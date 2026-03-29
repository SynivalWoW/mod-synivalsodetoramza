/*
 * mod_random_enchants_integration.cpp
 *
 * Integration of mod-random-enchants into the Synival Paragon bundle.
 *
 * Behaviour
 * ──────────
 *   When a player receives an eligible item (weapon or armour, Uncommon+),
 *   a random enchantment is applied to its permanent enchantment slot from a
 *   configurable weighted pool stored in the world database table
 *   `synival_random_enchants`. Each row has an enchant_id and a weight.
 *   The selection uses a weighted random draw: higher weight = higher chance.
 *
 *   Triggers:
 *     • OnPlayerLootItem  — items looted from creatures, chests, and quest
 *                           rewards (all use StoreLootItem in AC 3.3.5a)
 *
 *   Note: PlayerScript::OnQuestRewardItem does not exist in AzerothCore
 *   3.3.5a. Quest reward items pass through the same StoreLootItem codepath
 *   as creature loot, so OnPlayerLootItem covers both cases correctly.
 *
 *   Items that already carry a permanent enchantment (e.g. from a crafter)
 *   are not overwritten.
 *
 * Configuration (conf/mod_synival_paragon.conf.dist additions)
 * ─────────────────────────────────────────────────────────────
 *   RandomEnchants.Enable        = 1
 *   RandomEnchants.Chance        = 30   # % chance per eligible item
 *   RandomEnchants.MinQuality    = 2    # 2 = Uncommon, 3 = Rare, 4 = Epic
 *
 * SQL (world DB)
 * ──────────────
 *   CREATE TABLE IF NOT EXISTS synival_random_enchants (
 *     id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 *     enchant_id INT UNSIGNED NOT NULL,
 *     weight     INT UNSIGNED NOT NULL DEFAULT 1
 *   );
 *   -- Example rows (Wrath enchantment IDs):
 *   INSERT INTO synival_random_enchants (enchant_id, weight) VALUES
 *     (2673, 10),  -- Mongoose
 *     (3789, 10),  -- Berserking
 *     (3790, 10),  -- Black Magic
 *     (3232, 8),   -- Tuskarr's Vitality
 *     (1953, 6),   -- Crusader (classic feel)
 *     (2564, 6),   -- Executioner
 *     (3225, 5),   -- Accuracy
 *     (3370, 5),   -- Exceptional Agility
 *     (3371, 5),   -- Greater Assault
 *     (3844, 3);   -- Blade Ward (rare)
 *
 * AzerothCore Doxygen references:
 *   Item::GetEnchantmentId(EnchantmentSlot)
 *   Item::SetEnchantment(slot, id, duration, charges)
 *   Item::SetState(ITEM_CHANGED, player)
 *   ItemTemplate::Quality / Class / SubClass
 *   Player::StoreLootItem — fires OnPlayerLootItem
 *   WorldScript::OnStartup — used for loading enchant pool at startup
 */

#include "ScriptMgr.h"
#include "Config.h"
#include "Chat.h"
#include "Item.h"
#include "Player.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Random.h"
#include <vector>
#include <mutex>

// ─────────────────────────────────────────────────────────────────────────────
// Runtime state
// ─────────────────────────────────────────────────────────────────────────────

struct RandomEnchantEntry
{
    uint32 enchantId;
    uint32 weight;
};

static bool                          g_REnable       = true;
static uint32                        g_RChance       = 30;
static uint32                        g_RMinQuality   = ITEM_QUALITY_UNCOMMON;
static std::vector<RandomEnchantEntry> g_EnchantPool;
static uint32                        g_TotalWeight   = 0;
static std::mutex                    g_REnchMutex;

// ─────────────────────────────────────────────────────────────────────────────
// Pool loader
// ─────────────────────────────────────────────────────────────────────────────

static void LoadRandomEnchantPool()
{
    std::lock_guard<std::mutex> lock(g_REnchMutex);
    g_EnchantPool.clear();
    g_TotalWeight = 0;

    QueryResult result = WorldDatabase.Query(
        "SELECT enchant_id, weight FROM synival_random_enchants ORDER BY id");
    if (!result)
    {
        LOG_WARN("module", "mod-random-enchants: synival_random_enchants table is empty "
                           "or missing. Using built-in fallback pool.");
        // Built-in fallback: classic Wrath weapon enchantments
        static const RandomEnchantEntry FALLBACK[] = {
            { 2673, 10 }, { 3789, 10 }, { 3790, 10 },
            { 3232, 8  }, { 1953, 6  }, { 2564, 6  },
            { 3225, 5  }, { 3370, 5  }, { 3371, 5  },
            { 3844, 3  },
        };
        for (auto const& e : FALLBACK)
        {
            g_EnchantPool.push_back(e);
            g_TotalWeight += e.weight;
        }
        return;
    }

    do
    {
        Field* f = result->Fetch();
        RandomEnchantEntry e;
        e.enchantId = f[0].Get<uint32>();
        e.weight    = f[1].Get<uint32>();
        if (e.weight == 0) continue;
        g_EnchantPool.push_back(e);
        g_TotalWeight += e.weight;
    } while (result->NextRow());

    LOG_INFO("module", "mod-random-enchants: Loaded {} enchantments (total weight: {}).",
             g_EnchantPool.size(), g_TotalWeight);
}

// ─────────────────────────────────────────────────────────────────────────────
// Weighted random draw
// ─────────────────────────────────────────────────────────────────────────────

/**
 * @brief Select a random enchant_id from the pool using weighted probability.
 * @return 0 if the pool is empty.
 */
static uint32 RollRandomEnchant()
{
    std::lock_guard<std::mutex> lock(g_REnchMutex);
    if (g_EnchantPool.empty() || g_TotalWeight == 0) return 0;

    uint32 roll = urand(0, g_TotalWeight - 1);
    uint32 cumulative = 0;
    for (auto const& e : g_EnchantPool)
    {
        cumulative += e.weight;
        if (roll < cumulative)
            return e.enchantId;
    }
    return g_EnchantPool.back().enchantId;
}

// ─────────────────────────────────────────────────────────────────────────────
// Apply helper
// ─────────────────────────────────────────────────────────────────────────────

/**
 * @brief Attempt to apply a random enchant to an item if eligible.
 *
 * Eligibility:
 *   • Item class must be ITEM_CLASS_WEAPON or ITEM_CLASS_ARMOR
 *   • Quality >= g_RMinQuality (default: Uncommon)
 *   • No existing permanent enchantment (slot 0 == PERM_ENCHANTMENT_SLOT)
 *   • Passes g_RChance % roll
 *
 * @param player  The player who owns the item.
 * @param item    The item to potentially enchant. Must be non-null.
 */
static void TryApplyRandomEnchant(Player* player, Item* item)
{
    if (!g_REnable || !item) return;

    ItemTemplate const* proto = item->GetTemplate();
    if (!proto) return;
    if (proto->Class != ITEM_CLASS_WEAPON && proto->Class != ITEM_CLASS_ARMOR) return;
    if (proto->Quality < g_RMinQuality) return;
    // Do not overwrite an existing permanent enchantment
    if (item->GetEnchantmentId(PERM_ENCHANTMENT_SLOT) != 0) return;
    if (!roll_chance_i(static_cast<int32>(g_RChance))) return;

    uint32 enchantId = RollRandomEnchant();
    if (!enchantId) return;

    item->SetEnchantment(PERM_ENCHANTMENT_SLOT, enchantId, 0, 0);
    item->SetState(ITEM_CHANGED, player);

    ChatHandler(player->GetSession()).PSendSysMessage(
        "|cff0070dd[Random Enchant]|r |cffFFD700{}|r received a random enchantment!",
        proto->Name1);
}

// ─────────────────────────────────────────────────────────────────────────────
// WorldScript — config + pool load
// ─────────────────────────────────────────────────────────────────────────────

class RandomEnchantsWorldScript : public WorldScript
{
public:
    RandomEnchantsWorldScript() : WorldScript("RandomEnchantsWorldScript") {}

    void OnBeforeConfigLoad(bool /*reload*/) override
    {
        g_REnable     = sConfigMgr->GetOption<bool>  ("RandomEnchants.Enable",     true);
        g_RChance     = sConfigMgr->GetOption<uint32>("RandomEnchants.Chance",     30);
        g_RMinQuality = sConfigMgr->GetOption<uint32>("RandomEnchants.MinQuality", ITEM_QUALITY_UNCOMMON);
        LoadRandomEnchantPool();
        LOG_INFO("module", "mod-random-enchants: Module {}. Chance: {}%.",
                 g_REnable ? "ENABLED" : "DISABLED", g_RChance);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// PlayerScript — hook into loot and quest reward
// ─────────────────────────────────────────────────────────────────────────────

class RandomEnchantsPlayerScript : public PlayerScript
{
public:
    RandomEnchantsPlayerScript() : PlayerScript("RandomEnchantsPlayerScript") {}

    /// Fires when a player stores a loot item (creature loot, chest, quest reward).
    void OnPlayerLootItem(Player* player, Item* item,
                          uint32 /*count*/, ObjectGuid /*lootguid*/) override
    {
        if (!g_REnable || !item || !player) return;
        if (!item->IsInWorld()) return;
        TryApplyRandomEnchant(player, item);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Registration
// ─────────────────────────────────────────────────────────────────────────────

void AddSC_mod_random_enchants()
{
    new RandomEnchantsWorldScript();
    new RandomEnchantsPlayerScript();
}
