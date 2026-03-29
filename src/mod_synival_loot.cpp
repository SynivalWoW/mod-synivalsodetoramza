/*
 * mod_synival_loot.cpp  (auto-loot-on-kill variant)
 *
 * Loot is collected automatically when a player kills a creature.
 * No right-click is required.
 *
 * Kill-to-loot timing — why a deferred queue is required
 * ────────────────────────────────────────────────────────
 * Unit::Kill() call sequence:
 *   1. sScriptMgr->OnPlayerKilledUnit()  <-- OnPlayerCreatureKill fires HERE
 *   2. victim->setDeathState(JUST_DIED)
 *   3. victim->JustDied()               <-- loot generated, LOOTABLE flag set
 *
 * Steps 1 fires before step 3. Any loot access at step 1 reads an empty or
 * uninitialised loot object, causing a crash. This was the root cause of the
 * original ACCESS_VIOLATION bug.
 *
 * Fix: deferred queue drained by WorldScript::OnUpdate
 *   1. OnPlayerCreatureKill pushes {playerGuid, creatureGuid} to g_AutoLootPending.
 *   2. OnUpdate checks each entry every tick:
 *        HasDynamicFlag(UNIT_DYNFLAG_LOOTABLE) -> loot ready -> process
 *        elapsed < TIMEOUT                     -> not ready  -> wait
 *        elapsed >= TIMEOUT                    -> stale      -> discard
 *
 * AUTO-SELL FIX (this revision)
 * ──────────────────────────────
 * Root cause: HandleAutoSellItem Mode-0 (default) queued the item GUID into
 * g_VendorSellQueue and deferred sell+destroy to ProcessVendorSellQueue,
 * which only fired on CMSG_LIST_INVENTORY (vendor open). Two failure paths:
 *   (a) Player never visited a vendor — queue never drained, items never sold.
 *   (b) Item* could be invalidated by the time vendor-open fired.
 * Fix: Both AutoSellMode 0 and 1 now sell and destroy at loot time. Bag/slot
 * coordinates are captured before DestroyItem. g_PendingSells summary is still
 * populated for the combat-leave report. ProcessVendorSellQueue is a no-op.
 *
 * Doxygen references:
 *   WorldScript::OnUpdate(uint32 diff)
 *   ObjectAccessor::FindPlayer
 *   Map::GetCreature
 *   Creature::HasDynamicFlag / RemoveDynamicFlag / AllLootRemovedFromCorpse
 *   Player::StoreLootItem / SetLootGUID / GetLootGUID / SendLootRelease
 *   Loot::isLooted / Loot::empty
 *   LootItem::AllowedForPlayer
 *   Group::NeedBeforeGreed / GetLootMethod
 */

#include "mod_synival_loot.h"
#include "mod_paragon_board.h"
#include "ScriptMgr.h"
#include "ServerScript.h"
#include "Config.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "ChatCommandArgs.h"
#include "ScriptedGossip.h"
#include "ObjectMgr.h"
#include "ObjectAccessor.h"
#include "World.h"
#include "WorldSessionMgr.h"
#include "Opcodes.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include "Map.h"
#include "Corpse.h"
#include "StringConvert.h"
#include "Log.h"
#include "GameObject.h"
#include "GridNotifiers.h"
#include "CellImpl.h"
#include "SkillDiscovery.h"
#include <fmt/format.h>
#include <sstream>
#include <algorithm>
#include <list>

// ─────────────────────────────────────────────────────────────────────────────
// Globals
// ─────────────────────────────────────────────────────────────────────────────

SynivalLootConfig                                            g_LootConfig;
std::mutex                                                   g_LootMutex;
std::unordered_map<ObjectGuid, std::vector<AutoSellEntry>>  g_PendingSells;
std::unordered_map<ObjectGuid, std::vector<ObjectGuid>>     g_VendorSellQueue; // kept for linker compat
std::unordered_map<ObjectGuid, bool>                        g_ChosenAuraActive;
std::vector<AutoLootPendingEntry>                           g_AutoLootPending;
std::vector<AutoSkinPendingEntry>                           g_AutoSkinPending;
std::unordered_map<ObjectGuid, uint32>                      g_GatherTimers;

// ─────────────────────────────────────────────────────────────────────────────
// Config
// ─────────────────────────────────────────────────────────────────────────────

void SynivalLootConfig::Load()
{
    Enable               = sConfigMgr->GetOption<bool>  ("Loot.Enable",               true);
    ScalingEnable        = sConfigMgr->GetOption<bool>  ("Loot.ScalingEnable",        true);
    ParagonScalePerLevel = sConfigMgr->GetOption<float> ("Loot.ParagonScalePerLevel",  0.005f);
    AutoLootOnKill       = sConfigMgr->GetOption<bool>  ("Loot.AutoLootOnKill",       true);
    AutoLootShareGold    = sConfigMgr->GetOption<bool>  ("Loot.AutoLootShareGold",    true);
    AutoSkin             = sConfigMgr->GetOption<bool>  ("Loot.AutoSkin",             true);
    AutoGather           = sConfigMgr->GetOption<bool>  ("Loot.AutoGather",           true);
    AutoChest            = sConfigMgr->GetOption<bool>  ("Loot.AutoChest",            true);
    AutoGatherRange      = sConfigMgr->GetOption<float> ("Loot.AutoGatherRange",      30.0f);
    AutoSellEnable       = sConfigMgr->GetOption<bool>  ("Loot.AutoSellEnable",       true);
    AutoSellMode         = sConfigMgr->GetOption<uint32>("Loot.AutoSellMode",          0);
    AutoSellGrayItems    = sConfigMgr->GetOption<bool>  ("Loot.AutoSellGrayItems",    true);
    LegendaryCostGold    = sConfigMgr->GetOption<uint32>("Loot.LegendaryCostGold",    5000000);
    LegendaryCostShards  = sConfigMgr->GetOption<uint32>("Loot.LegendaryCostShards",  50);
    ShardDropChance      = sConfigMgr->GetOption<uint32>("Loot.ShardDropChance",      10);
    CoffingtonBypassSpellId = sConfigMgr->GetOption<uint32>("Loot.CoffingtonBypassSpellId", 60000);

    // Propagate to file-scope global used by ProcessAutoSkin/ProcessAutoGather.
    g_CoffingtonBypassSpell = CoffingtonBypassSpellId;

    TierMultiplier[TIER_NORMAL]         = sConfigMgr->GetOption<float>("Loot.TierMult.Normal",        1.0f);
    TierMultiplier[TIER_HEROIC]         = sConfigMgr->GetOption<float>("Loot.TierMult.Heroic",        1.25f);
    TierMultiplier[TIER_MYTHIC]         = sConfigMgr->GetOption<float>("Loot.TierMult.Mythic",        1.5f);
    TierMultiplier[TIER_ASCENDED]       = sConfigMgr->GetOption<float>("Loot.TierMult.Ascended",      2.0f);
    TierMultiplier[TIER_SYNIVAL_CHOSEN] = sConfigMgr->GetOption<float>("Loot.TierMult.SynivalChosen", 3.0f);

    TierChance[TIER_NORMAL]         = sConfigMgr->GetOption<uint32>("Loot.TierChance.Normal",        60);
    TierChance[TIER_HEROIC]         = sConfigMgr->GetOption<uint32>("Loot.TierChance.Heroic",        25);
    TierChance[TIER_MYTHIC]         = sConfigMgr->GetOption<uint32>("Loot.TierChance.Mythic",        10);
    TierChance[TIER_ASCENDED]       = sConfigMgr->GetOption<uint32>("Loot.TierChance.Ascended",      4);
    TierChance[TIER_SYNIVAL_CHOSEN] = sConfigMgr->GetOption<uint32>("Loot.TierChance.SynivalChosen", 1);
}

void LoadLootConfig()
{
    g_LootConfig.Load();
    LOG_INFO("module", "mod-synival-loot (auto-loot-on-kill): Module {}.",
             g_LootConfig.Enable ? "ENABLED" : "DISABLED");
}

// ─────────────────────────────────────────────────────────────────────────────
// Tier roll
// ─────────────────────────────────────────────────────────────────────────────

LootTier RollLootTier()
{
    uint32 roll = urand(0, 99);
    uint32 cumulative = 0;
    for (uint8 i = 0; i < TIER_MAX; ++i)
    {
        cumulative += g_LootConfig.TierChance[i];
        if (roll < cumulative)
            return static_cast<LootTier>(i);
    }
    return TIER_NORMAL;
}

// ─────────────────────────────────────────────────────────────────────────────
// Item scaling
// ─────────────────────────────────────────────────────────────────────────────

void ApplyItemScaling(Player* player, Item* item, LootTier tier)
{
    if (!g_LootConfig.ScalingEnable || !item) return;
    ItemTemplate const* proto = item->GetTemplate();
    if (!proto || proto->Quality < ITEM_QUALITY_UNCOMMON) return;
    item->SetEnchantment(PERM_ENCHANTMENT_SLOT, static_cast<uint32>(tier) + 100u, 0, 0);
    item->SetState(ITEM_CHANGED, player);
}

// ─────────────────────────────────────────────────────────────────────────────
// Gold formatter
// ─────────────────────────────────────────────────────────────────────────────

std::string FormatGold(uint32 copper)
{
    uint32 g = copper / 10000;
    uint32 s = (copper % 10000) / 100;
    uint32 c = copper % 100;
    std::ostringstream ss;
    if (g) ss << g << "g ";
    if (s) ss << s << "s ";
    if (c || (!g && !s)) ss << c << "c";
    std::string result = ss.str();
    while (!result.empty() && result.back() == ' ')
        result.pop_back();
    return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Auto-sell
// ─────────────────────────────────────────────────────────────────────────────

bool IsItemProtectedFromSell(ItemTemplate const* proto)
{
    if (!proto) return true;
    if (proto->Class == ITEM_CLASS_CONSUMABLE)  return true;
    if (proto->Class == ITEM_CLASS_TRADE_GOODS) return true;
    if (proto->Class == ITEM_CLASS_PROJECTILE)  return true;
    if (proto->Class == ITEM_CLASS_QUEST)       return true;
    if (proto->StartQuest > 0)                  return true;
    return false;
}

/**
 * @brief Immediately sell and destroy a gray or unprotected white item.
 *
 * Both AutoSellMode 0 (formerly deferred to vendor-open) and 1 (formerly
 * immediate) now execute the sell+destroy at loot time. Bag and slot
 * coordinates are captured before DestroyItem because the Item* becomes
 * invalid after destruction. The summary entry is pushed to g_PendingSells
 * so FlushAutoSellSummary on combat-leave can still print the report.
 *
 * Callers must confirm item->IsInWorld() before calling this function.
 */
void HandleAutoSellItem(Player* player, Item* item, ItemTemplate const* proto)
{
    if (!g_LootConfig.AutoSellEnable || !item || !proto) return;

    bool shouldSell = false;
    if (proto->Quality == ITEM_QUALITY_POOR)
        shouldSell = g_LootConfig.AutoSellGrayItems;
    else if (proto->Quality == ITEM_QUALITY_NORMAL && !IsItemProtectedFromSell(proto))
        shouldSell = true;

    if (!shouldSell) return;

    uint32 sellPrice = proto->SellPrice * item->GetCount();
    if (sellPrice == 0) return;

    // Capture slot info and count before DestroyItem (which invalidates item*).
    uint8  bagSlot  = item->GetBagSlot();
    uint8  itemSlot = item->GetSlot();
    uint32 count    = item->GetCount();

    AutoSellEntry entry;
    entry.name      = proto->Name1;
    entry.sellPrice = sellPrice;
    entry.count     = count;

    player->ModifyMoney(static_cast<int32>(sellPrice));
    player->DestroyItem(bagSlot, itemSlot, true);

    {
        std::lock_guard<std::mutex> lock(g_LootMutex);
        g_PendingSells[player->GetGUID()].push_back(std::move(entry));
    }
}

/**
 * @brief No-op retained for call-site compatibility with SynivalLootServerScript.
 *
 * All selling is now done immediately in HandleAutoSellItem.
 */
void ProcessVendorSellQueue(Player* /*player*/)
{
    // Intentional no-op. Items are sold and destroyed inline at loot time.
}

void FlushAutoSellSummary(Player* player)
{
    std::vector<AutoSellEntry> sells;
    {
        std::lock_guard<std::mutex> lock(g_LootMutex);
        auto it = g_PendingSells.find(player->GetGUID());
        if (it == g_PendingSells.end() || it->second.empty()) return;
        sells = std::move(it->second);
        it->second.clear();
    }

    uint32 totalCopper = 0;
    for (auto const& e : sells) totalCopper += e.sellPrice;
    if (totalCopper == 0) return;

    ChatHandler ch(player->GetSession());
    ch.PSendSysMessage("|cffFFD700[Auto-Sell]|r Sold {} item{} for |cffffd700{}|r:",
        sells.size(), sells.size() == 1 ? "" : "s", FormatGold(totalCopper));
    for (auto const& e : sells)
        ch.PSendSysMessage("  |cff888888{}|r x{} - |cffffd700{}|r",
            e.name, e.count, FormatGold(e.sellPrice));
}

// ─────────────────────────────────────────────────────────────────────────────
// Legendary stat application
// ─────────────────────────────────────────────────────────────────────────────

void ApplyLegendaryStats(Player* player, Item* item, bool apply)
{
    if (!item) return;
    ItemTemplate const* proto = item->GetTemplate();
    if (!proto) return;
    uint32 entry = proto->ItemId;
    if (entry < 99500 || entry > 99559) return;

    uint32 paragonLevel = GetPlayerParagonLevel(player->GetGUID());
    float  bonusPct     = static_cast<float>(paragonLevel) * 0.01f;
    if (bonusPct < 0.001f) return;

    static const UnitMods LEGEND_MODS[] = {
        UNIT_MOD_STAT_STRENGTH, UNIT_MOD_STAT_AGILITY, UNIT_MOD_STAT_STAMINA,
        UNIT_MOD_STAT_INTELLECT, UNIT_MOD_STAT_SPIRIT, UNIT_MOD_ATTACK_POWER
    };
    for (UnitMods mod : LEGEND_MODS)
        player->ApplyStatPctModifier(mod, TOTAL_PCT,
            apply ? bonusPct * 100.0f : -(bonusPct * 100.0f));
    player->UpdateAllStats();
}

/**
 * @brief Apply or remove Paragon-scaled stat bonuses for a non-legendary looted item.
 *
 * The tier is stored in PERM_ENCHANTMENT_SLOT as (tier + 100) at loot time.
 * On equip we read that value, compute the effective multiplier:
 *   bonus% = paragonLevel * ParagonScalePerLevel * tierMultiplier * 100
 * and apply it to all five primary stats + attack power + armor.
 *
 * This is a player-side percentage modifier, not an item_template modification,
 * so it scales cleanly with paragon progression and is removed on unequip.
 */
void ApplyScaledItemStats(Player* player, Item* item, bool apply)
{
    if (!g_LootConfig.ScalingEnable || !item) return;
    ItemTemplate const* proto = item->GetTemplate();
    if (!proto || proto->Quality < ITEM_QUALITY_UNCOMMON) return;

    // Legendaries use their own scaling path
    uint32 entry = proto->ItemId;
    if (entry >= 99500 && entry <= 99559) return;

    // Read tier from perm enchant slot (stored as tier + 100 at loot time)
    uint32 enchVal = item->GetEnchantmentId(PERM_ENCHANTMENT_SLOT);
    if (enchVal < 100 || enchVal >= 100 + TIER_MAX) return;

    LootTier tier = static_cast<LootTier>(enchVal - 100);

    uint32 paragonLevel = GetPlayerParagonLevel(player->GetGUID());
    float paragonFactor = 1.0f + static_cast<float>(paragonLevel)
                          * g_LootConfig.ParagonScalePerLevel;
    float tierMult      = g_LootConfig.TierMultiplier[tier];
    // Bonus % above base (base = 1.0x * 1.0 paragon)
    float bonusPct = (paragonFactor * tierMult - 1.0f) * 100.0f;
    if (bonusPct < 0.01f) return;

    static const UnitMods SCALE_MODS[] = {
        UNIT_MOD_STAT_STRENGTH, UNIT_MOD_STAT_AGILITY, UNIT_MOD_STAT_STAMINA,
        UNIT_MOD_STAT_INTELLECT, UNIT_MOD_STAT_SPIRIT,
        UNIT_MOD_ATTACK_POWER, UNIT_MOD_ARMOR
    };
    for (UnitMods mod : SCALE_MODS)
        player->ApplyStatPctModifier(mod, TOTAL_PCT,
            apply ? bonusPct : -bonusPct);
    player->UpdateAllStats();
}

void RefreshAllScaledStats(Player* player)
{
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
    {
        Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (!item) continue;
        ApplyScaledItemStats(player, item, false);
        ApplyScaledItemStats(player, item, true);
    }
}

void RefreshAllLegendaryStats(Player* player)
{
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
    {
        Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (!item) continue;
        uint32 entry = item->GetTemplate()->ItemId;
        if (entry >= 99500 && entry <= 99559)
        {
            ApplyLegendaryStats(player, item, false);
            ApplyLegendaryStats(player, item, true);
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Synival's Chosen aura management
// ─────────────────────────────────────────────────────────────────────────────

void UpdateChosenAura(Player* player)
{
    uint8  classId   = player->getClass();
    uint32 auraSpell = (classId < 12) ? CLASS_CHOSEN_AURA[classId] : 0;
    if (!auraSpell) return;

    bool hasChosen = false;
    for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
    {
        Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
        if (!item) continue;
        uint32 entry = item->GetTemplate()->ItemId;
        if (entry < 99500 || entry > 99559) continue;
        if (item->GetEnchantmentId(TEMP_ENCHANTMENT_SLOT) == 99999) { hasChosen = true; break; }
    }

    ObjectGuid guid = player->GetGUID();
    bool wasActive  = false;
    {
        std::lock_guard<std::mutex> lock(g_LootMutex);
        auto it = g_ChosenAuraActive.find(guid);
        wasActive = (it != g_ChosenAuraActive.end() && it->second);
        g_ChosenAuraActive[guid] = hasChosen;
    }

    if (hasChosen && !wasActive)
        player->AddAura(auraSpell, player);
    else if (!hasChosen && wasActive)
        player->RemoveAurasDueToSpell(auraSpell);
}

// ─────────────────────────────────────────────────────────────────────────────
// Paragon Shard drop on elite kill
// ─────────────────────────────────────────────────────────────────────────────

void RollShardDrop(Player* player, Creature* creature)
{
    if (!creature || !creature->isElite()) return;
    if (!roll_chance_i(static_cast<int32>(g_LootConfig.ShardDropChance))) return;

    uint32 newShards = ModifyPlayerParagonShards(player->GetGUID(), 1);

    ItemPosCountVec dest;
    if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, 99400, 1) == EQUIP_ERR_OK)
        if (Item* shard = player->StoreNewItem(dest, 99400, true))
            player->SendNewItem(shard, 1, false, true);

    ChatHandler(player->GetSession()).PSendSysMessage(
        "|cffFFD700[Paragon Shards]|r +1 Paragon Shard dropped. Total: |cff00FF00{}|r.",
        newShards);
}

// ─────────────────────────────────────────────────────────────────────────────
// Auto-loot helpers
// ─────────────────────────────────────────────────────────────────────────────

bool IsValidAutoLootTarget(Player* player, Creature* creature)
{
    if (!creature || !player)                                return false;
    if (creature->IsAlive())                                 return false;
    if (!creature->HasDynamicFlag(UNIT_DYNFLAG_LOOTABLE))    return false;
    if (creature->loot.empty() || creature->loot.isLooted()) return false;
    if (!creature->isTappedBy(player))                       return false;
    return true;
}

void ProcessCreatureAoeLoot(Player* player, Creature* creature)
{
    if (!creature || !player) return;

    ObjectGuid lguid = creature->GetGUID();
    Loot*      loot  = &creature->loot;
    Group*     group = player->GetGroup();

    ObjectGuid originalLootGuid = player->GetLootGUID();
    player->SetLootGUID(lguid);

    // Quest items
    const QuestItemMap& questItems = loot->GetPlayerQuestItems();
    auto qit = questItems.find(player->GetGUID());
    if (qit != questItems.end())
    {
        for (uint8 i = 0; i < qit->second->size(); ++i)
        {
            uint8 slot = static_cast<uint8>(loot->items.size() + i);
            InventoryResult msg = EQUIP_ERR_OK;
            player->StoreLootItem(slot, loot, msg);
        }
    }

    // Regular items
    LootMethod lootMethod   = group ? group->GetLootMethod() : FREE_FOR_ALL;
    bool       isGroupLoot  = (lootMethod == GROUP_LOOT || lootMethod == NEED_BEFORE_GREED);
    bool       isRoundRobin = (lootMethod == ROUND_ROBIN);

    for (uint8 slot = 0; slot < static_cast<uint8>(loot->items.size()); ++slot)
    {
        LootItem& lootItem = loot->items[slot];
        if (lootItem.is_looted || lootItem.is_blocked) continue;

        if (group && !lootItem.is_underthreshold && isGroupLoot
            && lootMethod != FREE_FOR_ALL && lootMethod != MASTER_LOOT)
        {
            group->NeedBeforeGreed(loot, creature);
            continue;
        }
        if (isRoundRobin && loot->roundRobinPlayer
            && loot->roundRobinPlayer != player->GetGUID()) continue;
        if (group && lootMethod == MASTER_LOOT
            && group->GetMasterLooterGuid() != player->GetGUID()) continue;
        if (!lootItem.AllowedForPlayer(player, lguid)) continue;

        player->SetLootGUID(lguid);
        InventoryResult msg = EQUIP_ERR_OK;
        player->StoreLootItem(slot, loot, msg);
    }

    // Gold
    if (loot->gold > 0)
    {
        uint32 gold = loot->gold;
        loot->gold  = 0;

        float shareRange = sConfigMgr->GetOption<float>("Loot.AutoLootShareRange", 60.0f);

        if (group && g_LootConfig.AutoLootShareGold)
        {
            std::vector<Player*> eligible;
            for (GroupReference* itr = group->GetFirstMember(); itr != nullptr; itr = itr->next())
            {
                Player* member = itr->GetSource();
                if (member && member->IsInWorld() && !member->isDead()
                    && member->IsWithinDistInMap(player, shareRange))
                    eligible.push_back(member);
            }
            if (!eligible.empty())
            {
                uint32 share = gold / static_cast<uint32>(eligible.size());
                for (Player* m : eligible)
                {
                    m->ModifyMoney(static_cast<int32>(share));
                    m->UpdateAchievementCriteria(ACHIEVEMENT_CRITERIA_TYPE_LOOT_MONEY, share);
                }
            }
            else
            {
                player->ModifyMoney(static_cast<int32>(gold));
                player->UpdateAchievementCriteria(ACHIEVEMENT_CRITERIA_TYPE_LOOT_MONEY, gold);
            }
        }
        else
        {
            player->ModifyMoney(static_cast<int32>(gold));
            player->UpdateAchievementCriteria(ACHIEVEMENT_CRITERIA_TYPE_LOOT_MONEY, gold);
        }
    }

    // Release
    if (loot->isLooted())
    {
        player->SendLootRelease(lguid);
        creature->RemoveDynamicFlag(UNIT_DYNFLAG_LOOTABLE);
        creature->AllLootRemovedFromCorpse();
    }

    player->SetLootGUID(originalLootGuid);
}

// ─────────────────────────────────────────────────────────────────────────────
// Auto-skinning
//
// Called from WorldScript::OnUpdate after the normal creature loot has been
// fully collected (UNIT_DYNFLAG_LOOTABLE clears from the corpse).
//
// Design notes:
//   • We check player->GetSkillValue(SKILL_SKINNING) >= creature's required
//     skinning level (pulled from CreatureTemplate::SkinLootId).
//   • FillLoot populates creature->loot from LootTemplates_Skinning using the
//     template ID stored in CreatureTemplate::SkinLootId.
//   • We then loop the standard StoreLootItem path so OnPlayerLootItem fires
//     for every skin item (triggering tier rolls, auto-sell, etc.).
//   • UNIT_DYNFLAG_LOOTABLE is re-set by FillLoot; we clear it afterward.
// ─────────────────────────────────────────────────────────────────────────────

static void ProcessAutoSkin(Player* player, Creature* creature)
{
    if (!player || !creature) return;
    if (creature->IsAlive())  return;

    CreatureTemplate const* cinfo = creature->GetCreatureTemplate();
    if (!cinfo || cinfo->SkinLootId == 0) return;

    // Skill gate: player must have Skinning trained to at least the minimum
    // level for this creature, OR own the Coffington profession bypass spell.
    uint32 reqSkill = std::max<uint32>(1, creature->GetLevel() * 5);
    bool hasBypass  = player->HasSpell(g_CoffingtonBypassSpell);
    if (!hasBypass && player->GetSkillValue(SKILL_SKINNING) < reqSkill) return;

    // Generate skinning loot into the creature's loot object.
    creature->loot.clear();
    creature->loot.FillLoot(cinfo->SkinLootId, LootTemplates_Skinning, player, true);

    if (creature->loot.empty()) return;

    // Set LOOTABLE so StoreLootItem won't reject the loot access.
    creature->SetDynamicFlag(UNIT_DYNFLAG_LOOTABLE);

    ObjectGuid lguid           = creature->GetGUID();
    ObjectGuid originalLootGuid = player->GetLootGUID();
    player->SetLootGUID(lguid);

    bool anySkinned = false;
    for (uint8 slot = 0; slot < static_cast<uint8>(creature->loot.items.size()); ++slot)
    {
        LootItem& li = creature->loot.items[slot];
        if (li.is_looted || !li.AllowedForPlayer(player, lguid)) continue;
        InventoryResult msg = EQUIP_ERR_OK;
        player->StoreLootItem(slot, &creature->loot, msg);
        if (msg == EQUIP_ERR_OK) anySkinned = true;
    }

    player->SetLootGUID(originalLootGuid);
    creature->RemoveDynamicFlag(UNIT_DYNFLAG_LOOTABLE);
    creature->AllLootRemovedFromCorpse();

    if (anySkinned)
    {
        // Update skinning skill and award XP.
        player->UpdateGatherSkill(SKILL_SKINNING, player->GetSkillValue(SKILL_SKINNING),
                                  reqSkill, 1, creature);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auto-gather: herbs, ore nodes, and chests
//
// Called from AllMapScript::OnMapUpdate on a 1-second interval per player.
// Scans all GameObjects within AutoGatherRange yards and interacts with any
// that are in a ready-to-harvest state, provided the player has the required
// gathering profession skill (or no skill for chests).
//
// GO type classification in WotLK 3.3.5a:
//   GAMEOBJECT_TYPE_CHEST (3) — herbs, ore nodes, locked/unlocked chests,
//                               fishing bobbers, and other containers all
//                               share this type. We differentiate by skill:
//   Herb nodes  → require SKILL_HERBALISM  (plant-type loot template entries)
//   Mining nodes → require SKILL_MINING
//   Chests      → no profession skill required
//
// The node type is inferred from the GO's loot template via the required skill
// stored in LockEntry (go->GetGOInfo()->chest.lockId → sLockStore). We take
// the simpler approach of checking the player's skills and letting go->Use()
// handle the loot generation — it will reject the interaction silently if the
// player lacks the skill, so over-triggering is safe.
//
// go->Use(player) triggers the complete normal gather flow:
//   • Skill check (rejects if too low — safe fallback)
//   • Loot generation via FillLoot
//   • Sends SMSG_GAMEOBJECT_DESPAWN_ANIM or equivalent
//   • Marks GO as go-state ACTIVE, starts respawn timer
//   • Awards skill points and craft XP
// ─────────────────────────────────────────────────────────────────────────────

static void ProcessAutoGather(Player* player)
{
    if (!player || !player->IsInWorld()) return;
    if (!g_LootConfig.AutoGather && !g_LootConfig.AutoChest) return;
    if (player->IsInCombat()) return;          // don't interrupt combat
    if (player->IsMounted())  return;          // mounted gathering feels exploity
    if (!player->IsAlive())   return;

    float range = g_LootConfig.AutoGatherRange;

    // Gather all nearby GameObjects in one cell sweep.
    std::list<GameObject*> goList;
    Acore::GameObjectInRangeCheck check(
        player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), range);
    Acore::GameObjectListSearcher<Acore::GameObjectInRangeCheck> searcher(
        player, goList, check);
    Cell::VisitGridObjects(player, searcher, range);

    for (GameObject* go : goList)
    {
        if (!go || !go->IsInWorld())                     continue;
        if (go->GetGoType() != GAMEOBJECT_TYPE_CHEST)    continue;
        if (go->GetGoState() != GO_STATE_READY)          continue;
        if (go->GetLootState() != GO_LOOT_STATE_NOT_LOOT) continue;
        if (!go->IsWithinDistInMap(player, range, true)) continue;

        // Identify what kind of node this is via the required skill in its lock.
        uint32 lockId   = go->GetGOInfo()->chest.lockId;
        bool isHerb     = false;
        bool isMine     = false;
        bool isChest    = false;

        if (lockId > 0)
        {
            LockEntry const* lockInfo = sLockStore.LookupEntry(lockId);
            if (lockInfo)
            {
                for (uint8 i = 0; i < MAX_LOCK_CASE; ++i)
                {
                    if (lockInfo->Type[i] == LOCK_KEY_SKILL)
                    {
                        uint32 skillId = lockInfo->Index[i];
                        if      (skillId == SKILL_HERBALISM) isHerb  = true;
                        else if (skillId == SKILL_MINING)    isMine  = true;
                    }
                }
            }
        }

        if (!isHerb && !isMine) isChest = true;

        // Apply feature toggles.
        if (isHerb  && !g_LootConfig.AutoGather) continue;
        if (isMine  && !g_LootConfig.AutoGather) continue;
        if (isChest && !g_LootConfig.AutoChest)  continue;

        // Profession bypass: players who own the Coffington bypass spell
        // (g_CoffingtonBypassSpell) can gather herb and ore nodes without
        // the profession trained. If the player has the bypass and currently
        // has 0 skill in the required profession, we grant them Apprentice
        // rank (skill value 1, max 75) so go->Use()'s internal CanUseLock()
        // check passes. This is intentionally permanent — the player has paid
        // for the privilege and should see the skill appear in their spellbook.
        // Players who already have some points in the skill are unaffected.
        if (player->HasSpell(g_CoffingtonBypassSpell) && (isHerb || isMine))
        {
            uint32 skillId = isHerb ? SKILL_HERBALISM : SKILL_MINING;
            if (player->GetSkillValue(skillId) == 0)
                player->SetSkill(skillId, 1, 1, 75);
        }

        // go->Use() is the authoritative gather path — it awards skill points,
        // queues the respawn timer, and fires all relevant hooks.
        go->Use(player);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// WorldScript — config reload + deferred loot queue drain
// ─────────────────────────────────────────────────────────────────────────────

class SynivalLootWorldScript : public WorldScript
{
public:
    SynivalLootWorldScript() : WorldScript("SynivalLootWorldScript") {}

    void OnBeforeConfigLoad(bool /*reload*/) override { LoadLootConfig(); }

    void OnUpdate(uint32 diff) override
    {
        if (!g_LootConfig.Enable) return;

        // ── Drain auto-loot queue ─────────────────────────────────────────────
        if (g_LootConfig.AutoLootOnKill && !g_AutoLootPending.empty())
        {
            std::vector<std::pair<ObjectGuid, ObjectGuid>> toProcess;
            {
                std::lock_guard<std::mutex> lock(g_LootMutex);
                auto it = g_AutoLootPending.begin();
                while (it != g_AutoLootPending.end())
                {
                    it->elapsed += diff;
                    if (it->elapsed >= AutoLootPendingEntry::AUTOLOOT_TIMEOUT_MS)
                    { it = g_AutoLootPending.erase(it); continue; }

                    Player* p = ObjectAccessor::FindPlayer(it->playerGuid);
                    if (!p || !p->IsInWorld())
                    { it = g_AutoLootPending.erase(it); continue; }

                    Creature* c = p->GetMap()->GetCreature(it->creatureGuid);
                    if (!c)
                    { it = g_AutoLootPending.erase(it); continue; }

                    if (!c->HasDynamicFlag(UNIT_DYNFLAG_LOOTABLE))
                    { ++it; continue; }

                    toProcess.emplace_back(it->playerGuid, it->creatureGuid);
                    it = g_AutoLootPending.erase(it);
                }
            }

            for (auto const& [pguid, cguid] : toProcess)
            {
                Player* player = ObjectAccessor::FindPlayer(pguid);
                if (!player || !player->IsInWorld()) continue;
                Creature* creature = player->GetMap()->GetCreature(cguid);
                if (!creature) continue;
                if (!IsValidAutoLootTarget(player, creature)) continue;
                ProcessCreatureAoeLoot(player, creature);
            }
        }

        // ── Drain auto-skin queue ─────────────────────────────────────────────
        // Auto-skin fires after the normal loot clears (LOOTABLE flag gone).
        // We poll until either the corpse is de-flagged or the timeout expires.
        if (g_LootConfig.AutoSkin && !g_AutoSkinPending.empty())
        {
            std::vector<std::pair<ObjectGuid, ObjectGuid>> toSkin;
            {
                std::lock_guard<std::mutex> lock(g_LootMutex);
                auto it = g_AutoSkinPending.begin();
                while (it != g_AutoSkinPending.end())
                {
                    it->elapsed += diff;
                    if (it->elapsed >= AutoSkinPendingEntry::AUTOSKIN_TIMEOUT_MS)
                    { it = g_AutoSkinPending.erase(it); continue; }

                    Player* p = ObjectAccessor::FindPlayer(it->playerGuid);
                    if (!p || !p->IsInWorld())
                    { it = g_AutoSkinPending.erase(it); continue; }

                    Creature* c = p->GetMap()->GetCreature(it->creatureGuid);
                    if (!c)
                    { it = g_AutoSkinPending.erase(it); continue; }

                    // Wait until normal loot is fully collected before skinning.
                    if (c->HasDynamicFlag(UNIT_DYNFLAG_LOOTABLE))
                    { ++it; continue; }

                    toSkin.emplace_back(it->playerGuid, it->creatureGuid);
                    it = g_AutoSkinPending.erase(it);
                }
            }

            for (auto const& [pguid, cguid] : toSkin)
            {
                Player* player = ObjectAccessor::FindPlayer(pguid);
                if (!player || !player->IsInWorld()) continue;
                Creature* creature = player->GetMap()->GetCreature(cguid);
                if (!creature) continue;
                ProcessAutoSkin(player, creature);
            }
        }
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// ServerScript — retained for call-site compat; ProcessVendorSellQueue is no-op
// ─────────────────────────────────────────────────────────────────────────────

class SynivalLootServerScript : public ServerScript
{
public:
    SynivalLootServerScript() : ServerScript("SynivalLootServerScript") {}

    bool CanPacketReceive(WorldSession* session, WorldPacket& packet) override
    {
        if (!g_LootConfig.Enable) return true;
        if (packet.GetOpcode() == CMSG_LIST_INVENTORY)
        {
            Player* player = session->GetPlayer();
            if (player && player->IsInWorld())
                ProcessVendorSellQueue(player); // no-op; kept for compatibility
        }
        return true;
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// PlayerScript
// ─────────────────────────────────────────────────────────────────────────────

class SynivalLootPlayerScript : public PlayerScript
{
public:
    SynivalLootPlayerScript() : PlayerScript("SynivalLootPlayerScript") {}

    void OnPlayerCreatureKill(Player* player, Creature* creature) override
    {
        if (!g_LootConfig.Enable || !player || !creature) return;

#ifdef PLAYERBOTS
        if (player->IsBot()) return;
#endif

        RollShardDrop(player, creature);

        if (!creature->hasLootRecipient()) return;
        if (!creature->isTappedBy(player)) return;

        std::lock_guard<std::mutex> lock(g_LootMutex);

        // Enqueue normal loot.
        if (g_LootConfig.AutoLootOnKill)
        {
            AutoLootPendingEntry entry;
            entry.playerGuid   = player->GetGUID();
            entry.creatureGuid = creature->GetGUID();
            entry.elapsed      = 0;
            g_AutoLootPending.push_back(entry);
        }

        // Enqueue auto-skin if this creature has a skinning loot table.
        if (g_LootConfig.AutoSkin &&
            creature->GetCreatureTemplate() &&
            creature->GetCreatureTemplate()->SkinLootId != 0)
        {
            AutoSkinPendingEntry skinEntry;
            skinEntry.playerGuid   = player->GetGUID();
            skinEntry.creatureGuid = creature->GetGUID();
            skinEntry.elapsed      = 0;
            g_AutoSkinPending.push_back(skinEntry);
        }
    }

    /**
     * Called after an item is stored into the player's bags from any loot source.
     *
     * Order of operations (important):
     *   1. HandleAutoSellItem — sells/destroys gray/white items immediately.
     *      After this call, item->IsInWorld() will be false if the item was sold.
     *   2. Early-return if item was sold (IsInWorld() check).
     *   3. Tier roll and scaling only apply to uncommon+ items that survive step 1.
     */
    void OnPlayerLootItem(Player* player, Item* item,
                          uint32 /*count*/, ObjectGuid /*lootguid*/) override
    {
        if (!g_LootConfig.Enable || !item || !player) return;
        if (!item->IsInWorld()) return;

        ItemTemplate const* proto = item->GetTemplate();
        if (!proto) return;

        // Sync Paragon Shard balance when shards are obtained via any means
        // (including .additem). This ensures the vendor purchase check always
        // reads the correct total from g_ParagonMap.
        if (proto->ItemId == 99400)
        {
            ModifyPlayerParagonShards(player->GetGUID(),
                static_cast<int32>(item->GetCount()));
        }

        // Step 1: auto-sell gray/white — must happen before tier logic.
        HandleAutoSellItem(player, item, proto);

        // Step 2: bail if item was just destroyed.
        if (!item->IsInWorld()) return;

        // Step 3: tier tag + scaling for uncommon and above only.
        if (proto->Quality < ITEM_QUALITY_UNCOMMON) return;

        LootTier tier = RollLootTier();
        if (tier != TIER_NORMAL)
            ChatHandler(player->GetSession()).PSendSysMessage(
                "{} {}", TIER_LABELS[tier], proto->Name1);

        ApplyItemScaling(player, item, tier);

        // ── Tier suffix tooltip tag (requires client DBC patch) ───────────
        // Stamps a cosmetic name suffix ("of the Heroic" etc.) onto the item.
        // Requires ItemRandomSuffix.dbc client patch (IDs 9901-9904) in
        // patch-A.MPQ AND the item_random_suffix SQL rows on the server.
        // Harmless if the DBC patch is absent — the suffix ID is stored and
        // the tooltip will show it once the patch is applied.
        if (tier > TIER_NORMAL)
        {
            static const int32 TIER_SUFFIX_IDS[TIER_MAX] =
                { 0, -9901, -9902, -9903, -9904 };
            item->SetUInt32Value(ITEM_FIELD_RANDOM_PROPERTIES_ID,
                                 static_cast<uint32>(TIER_SUFFIX_IDS[tier]));
            item->SetState(ITEM_CHANGED, player);
        }

        uint32 entry = proto->ItemId;
        if (tier == TIER_SYNIVAL_CHOSEN && entry >= 99500 && entry <= 99559)
        {
            item->SetEnchantment(TEMP_ENCHANTMENT_SLOT, 99999, 0, 0);
            item->SetState(ITEM_CHANGED, player);
            UpdateChosenAura(player);

            std::string msg = "|cffFF8000[Synival's Chosen]|r " +
                std::string(player->GetName()) +
                " has obtained a |cffFF8000Synival's Chosen|r " +
                std::string(proto->Name1.c_str()) + "!";

            WorldSessionMgr::SessionMap const& sessions = sWorldSessionMgr->GetAllSessions();
            for (auto const& [id, wsession] : sessions)
                if (wsession && wsession->GetPlayer() && wsession->GetPlayer()->IsInWorld())
                    ChatHandler(wsession).PSendSysMessage("{}", msg);
        }
    }

    void OnPlayerLeaveCombat(Player* player) override
    {
        if (!g_LootConfig.Enable || !g_LootConfig.AutoSellEnable) return;
        FlushAutoSellSummary(player);
    }

    void OnPlayerEquip(Player* player, Item* item, uint8, uint8, bool) override
    {
        if (!g_LootConfig.Enable || !item) return;
        uint32 entry = item->GetTemplate()->ItemId;
        if (entry >= 99500 && entry <= 99559)
        {
            ApplyLegendaryStats(player, item, true);
            UpdateChosenAura(player);
        }
        else
        {
            ApplyScaledItemStats(player, item, true);
        }
    }

    void OnPlayerUnequip(Player* player, Item* item) override
    {
        if (!g_LootConfig.Enable || !item) return;
        uint32 entry = item->GetTemplate()->ItemId;
        if (entry >= 99500 && entry <= 99559)
        {
            ApplyLegendaryStats(player, item, false);
            UpdateChosenAura(player);
        }
        else
        {
            ApplyScaledItemStats(player, item, false);
        }
    }

    void OnPlayerLogin(Player* player) override
    {
        if (!g_LootConfig.Enable) return;
        RefreshAllLegendaryStats(player);
        RefreshAllScaledStats(player);
        UpdateChosenAura(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        ObjectGuid guid = player->GetGUID();
        std::lock_guard<std::mutex> lock(g_LootMutex);
        g_AutoLootPending.erase(
            std::remove_if(g_AutoLootPending.begin(), g_AutoLootPending.end(),
                [&guid](AutoLootPendingEntry const& e) { return e.playerGuid == guid; }),
            g_AutoLootPending.end());
        g_AutoSkinPending.erase(
            std::remove_if(g_AutoSkinPending.begin(), g_AutoSkinPending.end(),
                [&guid](AutoSkinPendingEntry const& e) { return e.playerGuid == guid; }),
            g_AutoSkinPending.end());
        g_GatherTimers.erase(guid);
        g_PendingSells.erase(guid);
        g_VendorSellQueue.erase(guid);
        g_ChosenAuraActive.erase(guid);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Legendary Vendor NPCs
//
// Architecture
// ────────────
// LegendaryVendorBase  — shared gossip build + purchase logic.
//   Derived by:
//     npc_legendary_vendor          (entry 99995) — Warrior, Paladin, Mage,
//                                                   Priest, Warlock (multi-class,
//                                                   uses legacy 6-slot system)
//     npc_legendary_vendor_hunter   (entry 99991) — Hunter only
//     npc_legendary_vendor_dk       (entry 99992) — Death Knight only
//     npc_legendary_vendor_shaman   (entry 99993) — Shaman only
//     npc_legendary_vendor_druid    (entry 99994) — Druid only
//
// Extended vendors (Hunter/DK/Shaman/Druid) expose all 10 slots using
// GetLegendaryEntryExtended(), which reads from the 99560-99599 range.
// Slots 0-5 use LEGENDARY_SLOT_UNLOCK / LEGENDARY_SLOT_NAMES.
// Slots 6-9 use LEGENDARY_SLOT_UNLOCK_EXT / LEGENDARY_SLOT_NAMES_EXT.
//
// Class gate
// ──────────
// Each derived NPC checks m_allowedClasses in OnGossipHello and refuses
// interaction from any class not in that set, sending a dismissal message.
// ─────────────────────────────────────────────────────────────────────────────

enum LegendaryVendorActions
{
    // Slots 0-5 map to actions 10-15 (legacy armour/weapon)
    LV_BUY_SLOT_0  = 10,
    LV_BUY_SLOT_1  = 11,
    LV_BUY_SLOT_2  = 12,
    LV_BUY_SLOT_3  = 13,
    LV_BUY_SLOT_4  = 14,
    LV_BUY_SLOT_5  = 15,
    // Slots 6-9 map to actions 16-19 (rings + trinkets, extended classes only)
    LV_BUY_SLOT_6  = 16,
    LV_BUY_SLOT_7  = 17,
    LV_BUY_SLOT_8  = 18,
    LV_BUY_SLOT_9  = 19,
    LV_CLOSE       = 99,
};

// ─────────────────────────────────────────────────────────────────────────────
// Base class — shared build-menu and purchase logic
// ─────────────────────────────────────────────────────────────────────────────

class LegendaryVendorBase : public CreatureScript
{
protected:
    // Set of WoW class IDs this NPC will serve (empty = multi-class / legacy).
    std::vector<uint8> m_allowedClasses;
    // Gossip menu ID used for SendGossipMenuFor.
    uint32             m_gossipMenuId;
    // True if this vendor uses the extended 10-slot system (99560-99599).
    bool               m_extended;

    LegendaryVendorBase(char const* scriptName,
                        std::vector<uint8> allowedClasses,
                        uint32 gossipMenuId,
                        bool extended)
        : CreatureScript(scriptName),
          m_allowedClasses(std::move(allowedClasses)),
          m_gossipMenuId(gossipMenuId),
          m_extended(extended)
    {}

    // Returns true when player->getClass() is in m_allowedClasses.
    // Always returns true when m_allowedClasses is empty (legacy multi-class).
    bool IsClassAllowed(uint8 classId) const
    {
        if (m_allowedClasses.empty()) return true;
        for (uint8 c : m_allowedClasses)
            if (c == classId) return true;
        return false;
    }

    // Shared gossip builder — populates the menu with the correct slots.
    void BuildMenu(Player* player, Creature* creature)
    {
        uint32 paragonLevel = GetPlayerParagonLevel(player->GetGUID());
        uint32 shards       = GetPlayerParagonShards(player->GetGUID());
        uint8  cls          = player->getClass();

        ClearGossipMenuFor(player);

        // Header line: balance display
        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
            "|cffFFD700Legendary Equipment|r  "
            "Shards: |cff00FF00" + std::to_string(shards) + "|r",
            GOSSIP_SENDER_MAIN, LV_CLOSE);

        uint8 totalSlots = m_extended ? 10 : 6;

        for (uint8 slot = 0; slot < totalSlots; ++slot)
        {
            // Resolve item entry and unlock threshold for this slot
            uint32 itemEntry = 0;
            uint32 required  = 0;
            const char* slotName = nullptr;

            if (slot < 6)
            {
                itemEntry = m_extended
                    ? GetLegendaryEntryExtended(cls, slot)
                    : GetLegendaryEntry(cls, slot);
                required  = LEGENDARY_SLOT_UNLOCK[slot];
                slotName  = LEGENDARY_SLOT_NAMES[slot];
            }
            else
            {
                // slots 6-9 are rings/trinkets (extended only)
                uint8 extSlot = slot - 6;  // 0-3
                itemEntry = GetLegendaryEntryExtended(cls, slot);
                required  = LEGENDARY_SLOT_UNLOCK_EXT[extSlot];
                slotName  = LEGENDARY_SLOT_NAMES_EXT[extSlot];
            }

            std::string label;
            uint32      gossipAction = LV_CLOSE;

            if (!itemEntry)
            {
                label = "|cffFF4444[" + std::string(slotName) +
                        "] Not available for your class|r";
            }
            else if (paragonLevel < required)
            {
                label = "|cff666666[" + std::string(slotName) +
                        "] Requires Paragon " + std::to_string(required) + "|r";
            }
            else
            {
                label = "|cffFF8000[" + std::string(slotName) + "]|r"
                        "  |cffffd700" + std::to_string(g_LootConfig.LegendaryCostGold / 10000) + "g|r"
                        " + |cff00FF00" + std::to_string(g_LootConfig.LegendaryCostShards) + " Shards|r";
                gossipAction = LV_BUY_SLOT_0 + slot;
            }

            AddGossipItemFor(player,
                (gossipAction != LV_CLOSE) ? GOSSIP_ICON_MONEY_BAG : GOSSIP_ICON_CHAT,
                label, GOSSIP_SENDER_MAIN, gossipAction);
        }

        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Farewell.",
                         GOSSIP_SENDER_MAIN, LV_CLOSE);
        SendGossipMenuFor(player, m_gossipMenuId, creature->GetGUID());
    }

    // Shared purchase handler — resolves item entry from action, validates, deducts.
    bool HandlePurchase(Player* player, uint32 action)
    {
        CloseGossipMenuFor(player);
        if (action == LV_CLOSE) return true;

        uint8 slot = static_cast<uint8>(action - LV_BUY_SLOT_0);
        if (slot > 9) return true;

        uint8  cls          = player->getClass();
        uint32 paragonLevel = GetPlayerParagonLevel(player->GetGUID());
        uint32 shards       = GetPlayerParagonShards(player->GetGUID());
        ChatHandler ch(player->GetSession());

        // Resolve entry and required level again (can't trust client action alone)
        uint32 itemEntry = 0;
        uint32 required  = 0;

        if (slot < 6)
        {
            itemEntry = m_extended
                ? GetLegendaryEntryExtended(cls, slot)
                : GetLegendaryEntry(cls, slot);
            required  = LEGENDARY_SLOT_UNLOCK[slot];
        }
        else
        {
            itemEntry = GetLegendaryEntryExtended(cls, slot);
            required  = LEGENDARY_SLOT_UNLOCK_EXT[slot - 6];
        }

        if (!itemEntry)
        { ch.SendSysMessage("|cffFF4444[Legendary]|r No item available for your class."); return true; }
        if (paragonLevel < required)
        { ch.PSendSysMessage("|cffFF4444[Legendary]|r Requires Paragon |cff00FF00{}|r. Current: |cffFFFF00{}|r.", required, paragonLevel); return true; }
        if (!player->HasEnoughMoney(static_cast<int32>(g_LootConfig.LegendaryCostGold)))
        { ch.PSendSysMessage("|cffFF4444[Legendary]|r Need |cffffd700{}g|r.", g_LootConfig.LegendaryCostGold / 10000); return true; }
        if (shards < g_LootConfig.LegendaryCostShards)
        { ch.PSendSysMessage("|cffFF4444[Legendary]|r Need |cff00FF00{}|r shards, have |cff00FF00{}|r.", g_LootConfig.LegendaryCostShards, shards); return true; }

        // Deduct costs
        player->ModifyMoney(-static_cast<int32>(g_LootConfig.LegendaryCostGold));
        ModifyPlayerParagonShards(player->GetGUID(), -static_cast<int32>(g_LootConfig.LegendaryCostShards));

        // Award item
        ItemPosCountVec dest;
        if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, itemEntry, 1) == EQUIP_ERR_OK)
        {
            if (Item* item = player->StoreNewItem(dest, itemEntry, true))
            {
                player->SendNewItem(item, 1, true, false);
                ch.PSendSysMessage("|cffFF8000[Legendary]|r |cffFF8000{}|r acquired!", item->GetTemplate()->Name1);
            }
        }
        else
        {
            // Refund on full inventory
            player->ModifyMoney(static_cast<int32>(g_LootConfig.LegendaryCostGold));
            ModifyPlayerParagonShards(player->GetGUID(), static_cast<int32>(g_LootConfig.LegendaryCostShards));
            ch.SendSysMessage("|cffFF4444[Legendary]|r Inventory full — purchase refunded.");
        }
        return true;
    }

public:
    bool OnGossipHello(Player* player, Creature* creature) override
    {
        if (!g_LootConfig.Enable)
        { SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature->GetGUID()); return true; }

        if (!IsClassAllowed(player->getClass()))
        {
            ChatHandler(player->GetSession()).SendSysMessage(
                "|cffFF4444[Legendary]|r These items are not meant for you.");
            CloseGossipMenuFor(player);
            return true;
        }

        BuildMenu(player, creature);
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* /*creature*/,
                        uint32 /*sender*/, uint32 action) override
    {
        if (!IsClassAllowed(player->getClass()))
        { CloseGossipMenuFor(player); return true; }

        return HandlePurchase(player, action);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Derived vendor scripts — one registration per NPC
// ─────────────────────────────────────────────────────────────────────────────

// entry 99995 — Synival, Legendary Arcanist
// Serves: Warrior(1), Paladin(2), Priest(5), Mage(8), Warlock(9)
// Uses legacy 6-slot system (99500-99559).
class npc_legendary_vendor : public LegendaryVendorBase
{
public:
    npc_legendary_vendor() : LegendaryVendorBase(
        "npc_legendary_vendor",
        { 1, 2, 5, 8, 9 },   // Warrior, Paladin, Priest, Mage, Warlock
        99995,
        false) {}
};

// entry 99991 — Rhayara Swiftwind
// Serves: Hunter(3) only. Extended 10-slot set (99560-99569).
class npc_legendary_vendor_hunter : public LegendaryVendorBase
{
public:
    npc_legendary_vendor_hunter() : LegendaryVendorBase(
        "npc_legendary_vendor_hunter",
        { 3 },   // Hunter
        99991,
        true) {}
};

// entry 99992 — Velthas Dreadblade
// Serves: Death Knight(6) only. Extended 10-slot set (99570-99579).
class npc_legendary_vendor_dk : public LegendaryVendorBase
{
public:
    npc_legendary_vendor_dk() : LegendaryVendorBase(
        "npc_legendary_vendor_dk",
        { 6 },   // Death Knight
        99992,
        true) {}
};

// entry 99993 — Murak Stormcaller
// Serves: Shaman(7) only. Extended 10-slot set (99580-99589).
class npc_legendary_vendor_shaman : public LegendaryVendorBase
{
public:
    npc_legendary_vendor_shaman() : LegendaryVendorBase(
        "npc_legendary_vendor_shaman",
        { 7 },   // Shaman
        99993,
        true) {}
};

// entry 99994 — Sylara Hearthroot
// Serves: Druid(11) only. Extended 10-slot set (99590-99599).
class npc_legendary_vendor_druid : public LegendaryVendorBase
{
public:
    npc_legendary_vendor_druid() : LegendaryVendorBase(
        "npc_legendary_vendor_druid",
        { 11 },  // Druid
        99994,
        true) {}
};

// ─────────────────────────────────────────────────────────────────────────────
// AllMapScript — per-map per-tick GO proximity gather scan
//
// Fires OnMapUpdate every world tick for every loaded map. We throttle to
// once per second per player using g_GatherTimers to avoid hammering the
// cell visitor on every 50 ms tick.
//
// Only processes players on maps where gathering makes sense (open world +
// instances). Combat, mounted, and dead players are skipped inside
// ProcessAutoGather. The scan itself is lightweight — it queries the spatial
// index for GOs within AutoGatherRange yards, which is a standard cell sweep.
// ─────────────────────────────────────────────────────────────────────────────

class SynivalGatherAllMapScript : public AllMapScript
{
public:
    SynivalGatherAllMapScript()
        : AllMapScript("SynivalGatherAllMapScript",
            { ALLMAPHOOK_ON_MAP_UPDATE })
    {}

    void OnMapUpdate(Map* map, uint32 diff) override
    {
        if (!g_LootConfig.Enable) return;
        if (!g_LootConfig.AutoGather && !g_LootConfig.AutoChest) return;

        Map::PlayerList const& players = map->GetPlayers();
        if (players.isEmpty()) return;

        for (auto itr = players.begin(); itr != players.end(); ++itr)
        {
            Player* player = itr->GetSource();
            if (!player || !player->IsInWorld() || !player->IsAlive()) continue;

#ifdef PLAYERBOTS
            if (player->IsBot()) continue;
#endif

            ObjectGuid guid = player->GetGUID();

            // Throttle: accumulate diff, only scan once per second.
            g_GatherTimers[guid] += diff;
            if (g_GatherTimers[guid] < 1000) continue;
            g_GatherTimers[guid] = 0;

            ProcessAutoGather(player);
        }
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Script Registration
// ─────────────────────────────────────────────────────────────────────────────

void AddSC_mod_synival_loot()
{
    new SynivalLootWorldScript();
    new SynivalLootServerScript();
    new SynivalLootPlayerScript();
    new SynivalGatherAllMapScript();
    new npc_legendary_vendor();
    new npc_legendary_vendor_hunter();
    new npc_legendary_vendor_dk();
    new npc_legendary_vendor_shaman();
    new npc_legendary_vendor_druid();
}
