#pragma once
/*
 * mod_synival_loot.h  --  AUTO-LOOT-ON-KILL VARIANT
 *
 * Synival Loot System: item rarity tiers, stat scaling, auto-kill loot,
 * auto-sell, legendary class equipment, and Paragon Shard drops.
 *
 * Key difference from the AoE variant (mod-synival-paragon):
 *   This variant collects loot automatically when a player kills a creature.
 *   No right-click is required. No CMSG_LOOT intercept. No per-player toggle.
 *
 * Kill-to-loot timing — why a deferred queue is mandatory
 * ─────────────────────────────────────────────────────────
 * Unit::Kill() in Unit.cpp fires hooks in this order:
 *   1. sScriptMgr->OnPlayerKilledUnit()  <-- OnPlayerCreatureKill fires HERE
 *   2. victim->setDeathState(JUST_DIED)
 *   3. victim->JustDied()               <-- FillLoot() runs, UNIT_DYNFLAG_LOOTABLE set
 *
 * Step 1 fires before step 3. The loot vector is empty at step 1.
 * Calling StoreLootItem at step 1 produces an ACCESS_VIOLATION (null loot).
 * This was the root cause of the original crash in the first module version.
 *
 * Deferred queue approach (implemented here):
 *   OnPlayerCreatureKill  -> push {playerGuid, creatureGuid} to g_AutoLootPending
 *   WorldScript::OnUpdate -> each tick, check HasDynamicFlag(UNIT_DYNFLAG_LOOTABLE)
 *                            ready   -> call ProcessCreatureAoeLoot, remove entry
 *                            waiting -> leave in queue, increment elapsed
 *                            timeout -> discard (creature had no lootable items)
 *
 * Playerbots: guarded with #ifdef PLAYERBOTS / player->IsBot().
 */

#include "Player.h"
#include "Creature.h"
#include "Item.h"
#include "Group.h"
#include "LootMgr.h"
#include "ObjectAccessor.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "ChatCommand.h"
#include "ChatCommandArgs.h"
#include <unordered_map>
#include <vector>
#include <string>
#include <mutex>

using namespace Acore::ChatCommands;

// ─────────────────────────────────────────────────────────────────────────────
// Rarity tiers
// ─────────────────────────────────────────────────────────────────────────────

enum LootTier : uint8
{
    TIER_NORMAL         = 0,
    TIER_HEROIC         = 1,
    TIER_MYTHIC         = 2,
    TIER_ASCENDED       = 3,
    TIER_SYNIVAL_CHOSEN = 4,
    TIER_MAX            = 5,
};

// ─────────────────────────────────────────────────────────────────────────────
// Configuration struct
// All fields loaded from conf/mod_synival_paragon.conf.dist via Load()
// ─────────────────────────────────────────────────────────────────────────────

struct SynivalLootConfig
{
    bool   Enable               = true;

    bool   ScalingEnable        = true;
    float  ParagonScalePerLevel = 0.005f;

    float  TierMultiplier[TIER_MAX] = { 1.0f, 1.25f, 1.5f, 2.0f, 3.0f };
    uint32 TierChance[TIER_MAX]     = { 60, 25, 10, 4, 1 };

    // Auto-loot-on-kill  (conf: Loot.AutoLootOnKill, default 1)
    bool   AutoLootOnKill       = true;
    // Split gold among group  (conf: Loot.AutoLootShareGold, default 1)
    bool   AutoLootShareGold    = true;

    // Auto-skinning after creature kill (conf: Loot.AutoSkin, default 1)
    bool   AutoSkin             = true;
    // Auto-gather herbs and ore within range (conf: Loot.AutoGather, default 1)
    bool   AutoGather           = true;
    // Auto-loot nearby chests and containers (conf: Loot.AutoChest, default 1)
    bool   AutoChest            = true;
    // Radius in yards for GO auto-gather/chest scan (conf: Loot.AutoGatherRange, default 30.0)
    float  AutoGatherRange      = 30.0f;

    bool   AutoSellEnable       = true;
    uint32 AutoSellMode         = 0;
    bool   AutoSellGrayItems    = true;

    uint32 LegendaryCostGold    = 5000000;
    uint32 LegendaryCostShards  = 50;
    uint32 ShardDropChance      = 10;

    // Profession bypass spell (Ser Coffington, NPC 133700)
    uint32 CoffingtonBypassSpellId = 60000;

    void Load();
};

// ─────────────────────────────────────────────────────────────────────────────
// Tier display strings
// ─────────────────────────────────────────────────────────────────────────────

static const char* TIER_LABELS[TIER_MAX] =
{
    "|cffFFFFFF[Normal]|r",
    "|cff1eff00[Heroic]|r",
    "|cff0070dd[Mythic]|r",
    "|cffa335ee[Ascended]|r",
    "|cffFF8000[Synival's Chosen]|r",
};

static const char* TIER_NAMES[TIER_MAX] =
{
    "Normal", "Heroic", "Mythic", "Ascended", "Synival's Chosen"
};

// ─────────────────────────────────────────────────────────────────────────────
// Legendary slot definitions
//
// LEGACY classes (Warrior/Paladin/Hunter/Rogue/Priest/DK/Shaman/Mage/Warlock/Druid)
//   use entries 99500–99559 (6 slots each: Weapon–Boots).
//
// EXTENDED classes (Hunter/DK/Shaman/Druid — the new per-NPC vendors)
//   use entries 99560–99599 (10 slots each: Weapon–Boots + Ring1/Ring2/Trinket1/Trinket2).
//   Base offsets: Hunter=99560, DK=99570, Shaman=99580, Druid=99590.
// ─────────────────────────────────────────────────────────────────────────────

// Unlock thresholds for slots 0-5 (all classes)
static constexpr uint32 LEGENDARY_SLOT_UNLOCK[6] = { 25, 50, 75, 100, 125, 150 };

// Unlock thresholds for slots 6-9 (extended classes only)
static constexpr uint32 LEGENDARY_SLOT_UNLOCK_EXT[4] = { 25, 50, 75, 100 };

static const char* LEGENDARY_SLOT_NAMES[6] =
{
    "Weapon", "Helm", "Chest", "Gloves", "Legs", "Boots"
};

static const char* LEGENDARY_SLOT_NAMES_EXT[4] =
{
    "Ring 1", "Ring 2", "Trinket 1", "Trinket 2"
};

/// Returns item_template entry for a class+slot combination (slots 0-5).
/// Formula: 99500 + classIndex*6 + slotOffset.
/// classIndex: War=0 Pal=1 Hun=2 Rog=3 Pri=4 DK=5 Sha=6 Mag=7 Wlk=8 Dru=9
inline uint32 GetLegendaryEntry(uint8 classId, uint8 slotIndex)
{
    static const int8 CLASS_INDEX[12] =
        { -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, -1, 9 };
    if (classId > 11) return 0;
    int8 ci = CLASS_INDEX[classId];
    if (ci < 0 || slotIndex > 5) return 0;
    return 99500u + static_cast<uint32>(ci) * 6u + slotIndex;
}

/// Returns item_template entry for an extended-set class+slot (slots 0-9).
/// Only valid for Hunter(3), DK(6), Shaman(7), Druid(11).
/// Formula: base + slotOffset, where base is 99560/99570/99580/99590.
/// Returns 0 for classes that do not have an extended set.
inline uint32 GetLegendaryEntryExtended(uint8 classId, uint8 slotIndex)
{
    if (slotIndex > 9) return 0;
    uint32 base = 0;
    switch (classId)
    {
        case 3:  base = 99560; break; // Hunter
        case 6:  base = 99570; break; // Death Knight
        case 7:  base = 99580; break; // Shaman
        case 11: base = 99590; break; // Druid
        default: return 0;
    }
    return base + slotIndex;
}

// ─────────────────────────────────────────────────────────────────────────────
// Synival's Chosen visual aura per class
// ─────────────────────────────────────────────────────────────────────────────

static const uint32 CLASS_CHOSEN_AURA[12] =
{
    0,      // 0 unused
    7376,   // 1 Warrior      -- Berserker Stance glow
    46565,  // 2 Paladin      -- Ascension glow
    34074,  // 3 Hunter       -- Aspect of the Viper
    31224,  // 4 Rogue        -- Find Weakness
    27827,  // 5 Priest       -- Prayer of Shadow Protection
    48266,  // 6 Death Knight -- Frost Presence
    32182,  // 7 Shaman       -- Nature's Swiftness glow
    12043,  // 8 Mage         -- Presence of Mind
    18708,  // 9 Warlock      -- Fel Domination glow
    0,      // 10 unused
    24858,  // 11 Druid       -- Natural Perfection
};

// ─────────────────────────────────────────────────────────────────────────────
// Auto-sell accumulator entry
// ─────────────────────────────────────────────────────────────────────────────

struct AutoSellEntry
{
    std::string name;
    uint32      sellPrice = 0;
    uint32      count     = 1;
};

// ─────────────────────────────────────────────────────────────────────────────
// Ser Coffington — Profession Bypass
//
// Players who purchase "Master of All Trades" from Ser Coffington
// (NPC 133700) bypass the Herbalism, Mining, and Skinning skill gate in
// ProcessAutoGather / ProcessAutoSkin. The spell ID is configurable via
// Loot.CoffingtonBypassSpellId (default 60000). Defined in spell_dbc —
// no client-side DBC patch needed.
// ─────────────────────────────────────────────────────────────────────────────

// Loaded from config in SynivalLootConfig::Load(); used by both
// ProcessAutoSkin and ProcessAutoGather.
static uint32 g_CoffingtonBypassSpell = 60000;
//
// Populated in OnPlayerCreatureKill (loot not ready yet — JustDied not run).
// Drained by WorldScript::OnUpdate once UNIT_DYNFLAG_LOOTABLE is observed.
// elapsed tracks ms waited; entries >= AUTOLOOT_TIMEOUT_MS are discarded.
// ─────────────────────────────────────────────────────────────────────────────

struct AutoLootPendingEntry
{
    ObjectGuid playerGuid;
    ObjectGuid creatureGuid;
    uint32     elapsed = 0;

    // Discard after 500 ms. Normal loot generation completes within one tick
    // (~50 ms). The generous window handles heavy-load edge cases.
    static constexpr uint32 AUTOLOOT_TIMEOUT_MS = 500;
};

// ─────────────────────────────────────────────────────────────────────────────
// Deferred auto-skin queue entry
//
// Populated alongside auto-loot when the creature has a SkinLootId.
// We wait until the normal loot has been fully collected (LOOTABLE flag gone)
// before attempting to skin, mirroring manual player behaviour.
// ─────────────────────────────────────────────────────────────────────────────

struct AutoSkinPendingEntry
{
    ObjectGuid playerGuid;
    ObjectGuid creatureGuid;
    uint32     elapsed = 0;

    // Slightly longer timeout than normal loot — skin fires after loot clears.
    static constexpr uint32 AUTOSKIN_TIMEOUT_MS = 3000;
};

// ─────────────────────────────────────────────────────────────────────────────
// Globals -- defined in mod_synival_loot.cpp
// ─────────────────────────────────────────────────────────────────────────────

extern SynivalLootConfig                                            g_LootConfig;
extern std::mutex                                                   g_LootMutex;

/// Per-player sell summary (flushed on combat leave)
extern std::unordered_map<ObjectGuid, std::vector<AutoSellEntry>>  g_PendingSells;

/// Mode-0 vendor sell queue: player GUID -> item GUIDs to sell on next vendor visit
extern std::unordered_map<ObjectGuid, std::vector<ObjectGuid>>     g_VendorSellQueue;

/// Whether a Synival's Chosen aura is active per player
extern std::unordered_map<ObjectGuid, bool>                        g_ChosenAuraActive;

/// Deferred auto-loot queue — global vector, drained by WorldScript::OnUpdate
extern std::vector<AutoLootPendingEntry>                           g_AutoLootPending;

/// Deferred auto-skin queue — drained after normal loot clears from corpse
extern std::vector<AutoSkinPendingEntry>                           g_AutoSkinPending;

/// Per-player gather scan interval accumulator (ms since last GO scan)
extern std::unordered_map<ObjectGuid, uint32>                      g_GatherTimers;

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

void     LoadLootConfig();

LootTier RollLootTier();
void     ApplyItemScaling(Player* player, Item* item, LootTier tier);

bool     IsItemProtectedFromSell(ItemTemplate const* proto);
void     HandleAutoSellItem(Player* player, Item* item, ItemTemplate const* proto);
void     FlushAutoSellSummary(Player* player);
void     ProcessVendorSellQueue(Player* player);

void     ApplyLegendaryStats(Player* player, Item* item, bool apply);
void     RefreshAllLegendaryStats(Player* player);
void     UpdateChosenAura(Player* player);

void     RollShardDrop(Player* player, Creature* creature);

/// Returns true when a creature corpse is ready for loot collection.
/// Checks UNIT_DYNFLAG_LOOTABLE, non-empty loot, and tapper eligibility.
bool     IsValidAutoLootTarget(Player* player, Creature* creature);

/// Loots all items + gold from a creature on behalf of the player,
/// honouring group loot rules and firing OnPlayerLootItem for every item.
/// Only call after HasDynamicFlag(UNIT_DYNFLAG_LOOTABLE) is confirmed.
void     ProcessCreatureAoeLoot(Player* player, Creature* creature);

std::string FormatGold(uint32 copper);
