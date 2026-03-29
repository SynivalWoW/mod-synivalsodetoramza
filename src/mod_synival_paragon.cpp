/*
 * mod_synival_paragon.cpp  — v3: Board System
 *
 * All v1 and v2 features are preserved.  New in v3:
 *
 *  ● Paragon Board System
 *    41 boards (1 universal, 10 class, 30 spec).
 *    Board Points earned: +1 per Paragon Level, 5% chance per creature kill.
 *    Node types: Normal (flat/1pt), Magic (flat/2pt), Rare (pct/3pt),
 *                Socket (glyph host/4pt), Start (free).
 *    Glyphs: amplify Rare nodes in Chebyshev radius, conditional bonuses.
 *    Removing a glyph returns the item to the player's bags.
 *
 *  ● Runic Archive gossip extended with full board navigation
 *  ● New .paragon board / .paragon points commands
 */

#include "mod_paragon_board.h"
#include "ScriptMgr.h"
#include "Item.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "Config.h"
#include "Group.h"
#include "ScriptedGossip.h"
#include "ObjectMgr.h"
#include "World.h"
#include "WorldSessionMgr.h"
#include "MapMgr.h"
#include "CommandScript.h"
#include "StringConvert.h"
#include "WorldPacket.h"
#include "Opcodes.h"
#include <sstream>
#include <ctime>

// ─────────────────────────────────────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────────────────────────────────────

struct SynivalParagonConfig
{
    bool   Enable                = true;
    uint32 XPPerParagonLevel     = 1500000;
    uint32 BaseParagonCap        = 200;
    uint32 ExtendedParagonCap    = 2000;
    uint32 MaxPrestige           = 10;
    float  StatBonusPerLevel     = 0.5f;   // +0.5% per level → +100% at cap 200
    float  StatBonusCap          = 100.0f; // hard ceiling on paragon stat bonus %
    float  MarkBonusPercent      = 15.0f;
    uint32 HiddenAffixChance     = 15;
    uint32 PrestigeAchievementId = 2139;
    uint32 KadalaCostStandard    = 10000;
    uint32 KadalaCostPremium     = 50000;
    uint32 BoardPointKillChance  = 5;
    uint32 PrestigeBoardPointBonus = 5;  // board points granted on each prestige

    uint32 SpellAscensionGlow    = 46565;
    uint32 SpellMaxParagonAura   = 72523;
    uint32 SpellLevelUpPillar    = 24750;

    uint32 NpcRunicArchiveEntry  = 99996;
    uint32 NpcKadalaEntry        = 99998;
    uint32 NpcButcherEntry       = 99997;
    uint32 ItemMarkAscensionEntry= 99300;
    uint32 ItemCacheEntry        = 99200;

    // ── Cache of Synival's Treasures drop configuration ───────────────────
    uint32 CacheShardMin        = 5;
    uint32 CacheShardMax        = 15;
    uint32 CacheEpicChance      = 25;   // % chance for Epic quality equipment
    uint32 CacheLegendaryChance = 5;    // % chance for Legendary quality equipment
                                         // Remaining (100 - Epic - Legendary) = Rare

    // ── Old-World Flying ──────────────────────────────────────────────────
    // Players possessing OldWorldFlyingSpellId can fly in Eastern Kingdoms
    // and Kalimdor. If OldWorldFlyingAllFly is true, the spell check is
    // bypassed entirely and all players may fly unconditionally.
    uint32 OldWorldFlyingSpellId = 200010;
    bool   OldWorldFlyingAllFly  = false;

    void Load()
    {
        Enable                = sConfigMgr->GetOption<bool>  ("Paragon.Enable",               true);
        XPPerParagonLevel     = sConfigMgr->GetOption<uint32>("Paragon.XPPerLevel",            1500000);
        BaseParagonCap        = sConfigMgr->GetOption<uint32>("Paragon.BaseCap",               200);
        ExtendedParagonCap    = sConfigMgr->GetOption<uint32>("Paragon.ExtendedCap",           2000);
        MaxPrestige           = sConfigMgr->GetOption<uint32>("Paragon.MaxPrestige",           10);
        StatBonusPerLevel     = sConfigMgr->GetOption<float> ("Paragon.StatBonusPerLevel",     0.5f);
        StatBonusCap          = sConfigMgr->GetOption<float> ("Paragon.StatBonusCap",          100.0f);
        MarkBonusPercent      = sConfigMgr->GetOption<float> ("Paragon.MarkBonusPercent",      15.0f);
        HiddenAffixChance     = sConfigMgr->GetOption<uint32>("Paragon.HiddenAffixChance",     15);
        PrestigeAchievementId = sConfigMgr->GetOption<uint32>("Paragon.PrestigeAchievId",      2139);
        KadalaCostStandard    = sConfigMgr->GetOption<uint32>("Paragon.KadalaCostStandard",    10000);
        KadalaCostPremium     = sConfigMgr->GetOption<uint32>("Paragon.KadalaCostPremium",     50000);
        BoardPointKillChance  = sConfigMgr->GetOption<uint32>("Paragon.BoardPointKillChance",  5);
        PrestigeBoardPointBonus = sConfigMgr->GetOption<uint32>("Paragon.PrestigeBoardPointBonus", 5);
        CacheShardMin        = sConfigMgr->GetOption<uint32>("Paragon.CacheShardMin",        5);
        CacheShardMax        = sConfigMgr->GetOption<uint32>("Paragon.CacheShardMax",        15);
        CacheEpicChance      = sConfigMgr->GetOption<uint32>("Paragon.CacheEpicChance",      25);
        CacheLegendaryChance = sConfigMgr->GetOption<uint32>("Paragon.CacheLegendaryChance", 5);

        OldWorldFlyingSpellId = sConfigMgr->GetOption<uint32>("OldWorldFlying.SpellId",       200010);
        OldWorldFlyingAllFly  = sConfigMgr->GetOption<bool>  ("OldWorldFlying.AllPlayersFly", false);
    }
};

static SynivalParagonConfig g_Config;

// ─────────────────────────────────────────────────────────────────────────────
// Item / NPC pools
// ─────────────────────────────────────────────────────────────────────────────

static const std::vector<uint32> KADALA_POOL_STANDARD =
    { 40395, 40396, 40397, 40398, 40399, 40400, 40401, 40402, 40403, 40404 };

static const std::vector<uint32> KADALA_POOL_PREMIUM =
    { 45825, 45826, 45827, 45828, 47706, 47707, 47708, 47709 };

static const std::vector<uint32> HIDDEN_AFFIX_POOL =
    { 2673, 3789, 3790, 3232, 1953, 2564 };

static const uint32 MILESTONE_TOAST_IDS[4] = { 2047, 2136, 4602, 1793 };

static const UnitMods STAT_MODS[5] = {
    UNIT_MOD_STAT_STRENGTH, UNIT_MOD_STAT_AGILITY, UNIT_MOD_STAT_STAMINA,
    UNIT_MOD_STAT_INTELLECT, UNIT_MOD_STAT_SPIRIT,
};

// ─────────────────────────────────────────────────────────────────────────────
// Formatting helpers
// ─────────────────────────────────────────────────────────────────────────────

static std::string FormatLargeNumber(uint32 n)
{
    std::string s = std::to_string(n);
    int32 pos = static_cast<int32>(s.size()) - 3;
    while (pos > 0) { s.insert(static_cast<size_t>(pos), ","); pos -= 3; }
    return s;
}

static std::string BuildProgressBar(uint32 current, uint32 max, uint32 width = 20)
{
    if (max == 0) return "[" + std::string(width, '-') + "]";
    uint32 filled = static_cast<uint32>((static_cast<uint64>(current) * width) / static_cast<uint64>(max));
    if (filled > width) filled = width;
    return "[|cff00cc00" + std::string(filled, '|') +
           "|cff555555" + std::string(width - filled, '-') + "|r]";
}

static std::string BuildPrestigeStars(uint32 current, uint32 max)
{
    std::string s = "|cffFFD700";
    for (uint32 i = 0; i < current && i < max; ++i) s += "*";
    s += "|cff555555";
    for (uint32 i = current; i < max; ++i) s += ".";
    return s + "|r";
}

// ─────────────────────────────────────────────────────────────────────────────
// Database helpers
// ─────────────────────────────────────────────────────────────────────────────

static void SavePlayerData(ObjectGuid guid, ParagonData const& data)
{
    CharacterDatabase.Execute(
        "REPLACE INTO character_paragon "
        "(guid, paragon_level, paragon_xp, prestige_count, "
        " last_cache_day, mark_used, board_points, "
        " paragon_shards, last_shard_purchase_day) "
        "VALUES ({}, {}, {}, {}, {}, {}, {}, {}, {})",
        guid.GetCounter(),
        data.paragonLevel, data.paragonXP, data.prestigeCount,
        data.lastCacheDay, data.markUsed ? 1 : 0, data.boardPoints,
        data.paragonShards, data.lastShardPurchaseDay);
}

static void LoadPlayerData(Player* player)
{
    ObjectGuid guid = player->GetGUID();
    QueryResult result = CharacterDatabase.Query(
        "SELECT paragon_level, paragon_xp, prestige_count, "
        "last_cache_day, mark_used, board_points, "
        "paragon_shards, last_shard_purchase_day "
        "FROM character_paragon WHERE guid = {}", guid.GetCounter());

    ParagonData data;
    if (result)
    {
        Field* f                   = result->Fetch();
        data.paragonLevel          = f[0].Get<uint32>();
        data.paragonXP             = f[1].Get<uint32>();
        data.prestigeCount         = f[2].Get<uint32>();
        data.lastCacheDay          = f[3].Get<uint32>();
        data.markUsed              = f[4].Get<uint8>() != 0;
        data.boardPoints           = f[5].Get<uint32>();
        data.paragonShards         = f[6].Get<uint32>();
        data.lastShardPurchaseDay  = f[7].Get<uint32>();
    }

    std::lock_guard<std::mutex> lock(g_ParagonMutex);
    g_ParagonMap[guid] = data;
}

// ─────────────────────────────────────────────────────────────────────────────
// Paragon-level stat scaling
// ─────────────────────────────────────────────────────────────────────────────

static void RefreshStatBonus(Player* player)
{
    ObjectGuid guid = player->GetGUID();
    uint32 appliedLevel, currentLevel;
    bool   appliedMark, currentMark;
    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        ParagonData& d  = g_ParagonMap[guid];
        appliedLevel    = d.appliedStatLevel;
        appliedMark     = d.appliedMark;
        currentLevel    = d.paragonLevel;
        currentMark     = d.markUsed;
    }

    // Remove old paragon-level bonus
    if (appliedLevel > 0)
    {
        float pct = std::min(
            static_cast<float>(appliedLevel) * g_Config.StatBonusPerLevel,
            g_Config.StatBonusCap);
        for (UnitMods mod : STAT_MODS)
            player->ApplyStatPctModifier(mod, TOTAL_PCT, -pct);
    }
    if (appliedMark)
        for (UnitMods mod : STAT_MODS)
            player->ApplyStatPctModifier(mod, TOTAL_PCT, -g_Config.MarkBonusPercent);

    // Apply board stats (remove then reapply to pick up any new nodes)
    ApplyAllBoardStats(player, false);

    // Reapply paragon-level bonus at new level
    if (currentLevel > 0)
    {
        float pct = std::min(
            static_cast<float>(currentLevel) * g_Config.StatBonusPerLevel,
            g_Config.StatBonusCap);
        for (UnitMods mod : STAT_MODS)
            player->ApplyStatPctModifier(mod, TOTAL_PCT, pct);
    }
    if (currentMark)
        for (UnitMods mod : STAT_MODS)
            player->ApplyStatPctModifier(mod, TOTAL_PCT, g_Config.MarkBonusPercent);

    ApplyAllBoardStats(player, true);
    player->UpdateAllStats();

    // Clamp run speed to 1.0 — high Agility scaling can inflate movement speed
    // as a side effect of ApplyStatPctModifier on UNIT_MOD_STAT_AGILITY.
    player->SetSpeed(MOVE_RUN, 1.0f, true);

    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        ParagonData& d     = g_ParagonMap[guid];
        d.appliedStatLevel = currentLevel;
        d.appliedMark      = currentMark;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cap helpers
// ─────────────────────────────────────────────────────────────────────────────

static uint32 GetCurrentCap(uint32 prestigeCount)
{
    return (prestigeCount >= g_Config.MaxPrestige)
        ? g_Config.ExtendedParagonCap : g_Config.BaseParagonCap;
}

// ─────────────────────────────────────────────────────────────────────────────
// UI helpers (SMSG_NOTIFICATION, achievement toast, etc.)
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// Broadcast helper — sends a system message to every online player
// (confirmed pattern from mod-world-chat, PR #19413 removed SendGlobalText)
// ─────────────────────────────────────────────────────────────────────────────
static void BroadcastToPlayers(std::string const& msg)
{
    WorldSessionMgr::SessionMap const& sessions = sWorldSessionMgr->GetAllSessions();
    for (auto const& [id, session] : sessions)
    {
        if (!session) continue;
        Player* target = session->GetPlayer();
        if (!target || !target->IsInWorld()) continue;
        ChatHandler(session).PSendSysMessage("{}", msg);
    }
}

static void SendParagonLevelUpPopup(Player* player, uint32 newLevel, uint32 cap)
{
    std::string msg;
    if (newLevel == cap)
        msg = "Paragon Cap Reached! Seek Prestige at the Runic Archive.";
    else
        msg = "Paragon Level " + std::to_string(newLevel) + " Reached!";

    WorldPacket data(SMSG_NOTIFICATION, msg.size() + 1);
    data << msg;
    player->GetSession()->SendPacket(&data);
}

static void SendMilestoneAchievementToast(Player* player, uint32 paragonLevel)
{
    uint32 idx;
    if      (paragonLevel <= 50)  idx = 0;
    else if (paragonLevel <= 100) idx = 1;
    else if (paragonLevel <= 150) idx = 2;
    else                          idx = 3;

    WorldPacket data(SMSG_ACHIEVEMENT_EARNED, 8 + 4 + 4 + 4);
    data << player->GetPackGUID();
    data << uint32(MILESTONE_TOAST_IDS[idx]);
    data.AppendPackedTime(time(nullptr));
    data << uint32(0);
    player->GetSession()->SendPacket(&data);
}

static void SendPrestigeToast(Player* player, uint32 prestigeRank)
{
    uint32 achievId = (prestigeRank >= 10) ? 1549u : 4602u;
    WorldPacket data(SMSG_ACHIEVEMENT_EARNED, 8 + 4 + 4 + 4);
    data << player->GetPackGUID();
    data << uint32(achievId);
    data.AppendPackedTime(time(nullptr));
    data << uint32(0);
    player->GetSession()->SendPacket(&data);
}

// ─────────────────────────────────────────────────────────────────────────────
// Paragon level-up handler
// ─────────────────────────────────────────────────────────────────────────────

static void HandleParagonLevelUp(Player* player)
{
    ObjectGuid guid = player->GetGUID();
    uint32 newLevel, prestige;
    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        newLevel = g_ParagonMap[guid].paragonLevel;
        prestige = g_ParagonMap[guid].prestigeCount;
    }
    uint32 cap = GetCurrentCap(prestige);

    SendParagonLevelUpPopup(player, newLevel, cap);
    player->CastSpell(player, g_Config.SpellLevelUpPillar, true);

    // Award 1 board point per paragon level
    AwardBoardPointOnLevelUp(player);

    bool isMilestone = (newLevel % 50 == 0) || (newLevel == cap);
    if (isMilestone)
    {
        std::string msg = "|cffffd700[Paragon]|r " + std::string(player->GetName()) +
            " has achieved |cff00ff00Paragon Level " + std::to_string(newLevel) + "|r!";
        BroadcastToPlayers(msg);
        SendMilestoneAchievementToast(player, newLevel);
    }

    if (newLevel == cap)
    {
        player->AddAura(g_Config.SpellMaxParagonAura, player);
        ChatHandler(player->GetSession()).PSendSysMessage(
            "|cffffd700[Paragon]|r Maximum Paragon Level |cff00ff00({})|r reached! "
            "Visit the |cffFF8000Runic Archive|r in Dalaran to Prestige.", cap);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Prestige helper
// ─────────────────────────────────────────────────────────────────────────────

static bool AttemptPrestige(Player* player)
{
    ObjectGuid guid = player->GetGUID();
    uint32 paragonLevel, prestigeCount;
    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        paragonLevel  = g_ParagonMap[guid].paragonLevel;
        prestigeCount = g_ParagonMap[guid].prestigeCount;
    }
    uint32 cap = GetCurrentCap(prestigeCount);

    ChatHandler ch(player->GetSession());

    if (paragonLevel < cap)
    {
        ch.PSendSysMessage(
            "|cffFF4444[Prestige]|r You must reach Paragon Level |cff00ff00{}|r first. "
            "Current: |cffFFFF00{}|r.", cap, paragonLevel);
        return false;
    }
    if (prestigeCount >= g_Config.MaxPrestige)
    {
        ch.PSendSysMessage(
            "|cffffd700[Prestige]|r Maximum Prestige Rank ({}) already achieved.",
            g_Config.MaxPrestige);
        return false;
    }
    if (!player->HasAchieved(g_Config.PrestigeAchievementId))
    {
        ch.PSendSysMessage(
            "|cffFF4444[Prestige]|r Complete all WotLK Heroic Dungeons first. "
            "(Achievement ID: {})", g_Config.PrestigeAchievementId);
        return false;
    }

    uint32 newPrestige;
    uint32 newBoardPoints;
    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        ParagonData& d  = g_ParagonMap[guid];
        d.paragonLevel  = 0;
        d.paragonXP     = 0;
        d.prestigeCount += 1;
        d.boardPoints   += g_Config.PrestigeBoardPointBonus;  // prestige board point reward
        newPrestige     = d.prestigeCount;
        newBoardPoints  = d.boardPoints;
        SavePlayerData(guid, d);
    }

    RefreshStatBonus(player);
    player->RemoveAura(g_Config.SpellMaxParagonAura);
    player->AddAura(g_Config.SpellAscensionGlow, player);

    std::string msg = "|cffFF8000[Prestige]|r " + std::string(player->GetName()) +
        " has achieved |cffFF8000Prestige Rank " + std::to_string(newPrestige) + "|r!";
    BroadcastToPlayers(msg);

    SendPrestigeToast(player, newPrestige);
    {
        std::string notifMsg = "Prestige Rank " + std::to_string(newPrestige) + " Achieved!";
        WorldPacket notifData(SMSG_NOTIFICATION, notifMsg.size() + 1);
        notifData << notifMsg;
        player->GetSession()->SendPacket(&notifData);
    }

    ch.PSendSysMessage(
        "|cffFF8000[Prestige]|r Complete! Rank |cffFF8000{}|r. "
        "Paragon Level reset. |cff00CCFF+{} Board Points|r granted. Stats recalculated.",
        newPrestige, g_Config.PrestigeBoardPointBonus);

    if (newPrestige == g_Config.MaxPrestige)
    {
        ch.PSendSysMessage(
            "|cffffd700[Prestige X]|r Extended cap unlocked: |cff00ff00{}|r Paragon Levels!",
            g_Config.ExtendedParagonCap);

        Position pos; pos.Relocate(5724.31f, 761.10f, 641.40f, 3.14f);
        if (Map* map = sMapMgr->FindMap(571, 0))
        {
            map->SummonCreature(g_Config.NpcButcherEntry, pos, nullptr, TEMPSUMMON_MANUAL_DESPAWN);
            std::string bossMsg =
                "|cffFF0000[World Event]|r The Butcher descends upon Dalaran! "
                + std::string(player->GetName()) + " has achieved Prestige X!";
            BroadcastToPlayers(bossMsg);
        }
        else
            LOG_ERROR("module", "mod-synival-paragon: Dalaran map (571) not found for Butcher spawn.");
    }
    return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// WorldScript
// ─────────────────────────────────────────────────────────────────────────────

class SynivalParagonWorldScript : public WorldScript
{
public:
    SynivalParagonWorldScript() : WorldScript("SynivalParagonWorldScript") {}

    void OnBeforeConfigLoad(bool /*reload*/) override
    {
        g_Config.Load();
        LoadAllBoardDefs();

        // Persist active config values to `synparagon_config` world DB table so
        // the Lua gossip script can read live values without hardcoding them.
        WorldDatabase.Execute(
            "REPLACE INTO `synparagon_config` "
            "(`cfg_key`, `cfg_value`) VALUES "
            "('BaseCap',              '{}'), "
            "('ExtendedCap',          '{}'), "
            "('MaxPrestige',          '{}'), "
            "('StatBonusPerLevel',    '{:.4f}'), "
            "('StatBonusCap',         '{:.1f}'), "
            "('MarkBonusPercent',     '{:.1f}'), "
            "('XPPerLevel',           '{}'), "
            "('PrestigeBoardPtBonus', '{}'), "
            "('BoardPointKillChance', '{}'), "
            "('HiddenAffixChance',    '{}'), "
            "('PrestigeAchievId',     '{}'), "
            "('ItemCacheEntry',       '{}')",
            g_Config.BaseParagonCap,
            g_Config.ExtendedParagonCap,
            g_Config.MaxPrestige,
            g_Config.StatBonusPerLevel,
            g_Config.StatBonusCap,
            g_Config.MarkBonusPercent,
            g_Config.XPPerParagonLevel,
            g_Config.PrestigeBoardPointBonus,
            g_Config.BoardPointKillChance,
            g_Config.HiddenAffixChance,
            g_Config.PrestigeAchievementId,
            g_Config.ItemCacheEntry);

        LOG_INFO("module", "mod-synival-paragon: Module {}.",
                 g_Config.Enable ? "ENABLED" : "DISABLED");
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// PlayerScript
// ─────────────────────────────────────────────────────────────────────────────

class SynivalParagonPlayerScript : public PlayerScript
{
public:
    SynivalParagonPlayerScript() : PlayerScript("SynivalParagonPlayerScript") {}

    // ── Paragon XP + board point on kill ─────────────────────────────────
    // xpSource param required by modern AzerothCore PlayerScript signature
    void OnPlayerGiveXP(Player* player, uint32& amount, Unit* victim, uint8 /*xpSource*/) override
    {
        if (!g_Config.Enable || player->GetLevel() < 80) return;

        // Board point chance: fires whenever XP comes from a creature kill
        if (victim && victim->GetTypeId() == TYPEID_UNIT)
        {
            if (roll_chance_i(static_cast<int32>(g_Config.BoardPointKillChance)))
                RollBoardPointOnKill(player);
        }

        uint32 xpGained = amount;
        amount = 0;

        ObjectGuid guid  = player->GetGUID();
        bool       leveled = false;
        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            ParagonData& d = g_ParagonMap[guid];
            uint32 cap     = GetCurrentCap(d.prestigeCount);
            if (d.paragonLevel >= cap) return;

            d.paragonXP += xpGained;
            while (d.paragonXP >= g_Config.XPPerParagonLevel && d.paragonLevel < cap)
            {
                d.paragonXP   -= g_Config.XPPerParagonLevel;
                d.paragonLevel++;
                leveled        = true;
            }
        }

        if (leveled)
        {
            {
                std::lock_guard<std::mutex> lock(g_ParagonMutex);
                SavePlayerData(guid, g_ParagonMap[guid]);
            }
            RefreshStatBonus(player);
            HandleParagonLevelUp(player);
        }
    }

    // ── Login: load data, refresh stats, daily cache, login message ───────
    void OnPlayerLogin(Player* player) override
    {
        if (!g_Config.Enable) return;

        LoadPlayerData(player);
        LoadBoardState(player);
        RefreshStatBonus(player);

        ObjectGuid guid  = player->GetGUID();
        uint32     today = static_cast<uint32>(std::time(nullptr) / 86400);
        bool       giveCache = false;
        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            ParagonData& d = g_ParagonMap[guid];
            if (d.lastCacheDay < today)
            {
                d.lastCacheDay = today;
                giveCache = true;
                SavePlayerData(guid, d);
            }
        }

        if (giveCache)
        {
            ItemPosCountVec dest;
            if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, g_Config.ItemCacheEntry, 1) == EQUIP_ERR_OK)
                if (Item* cache = player->StoreNewItem(dest, g_Config.ItemCacheEntry, true))
                    player->SendNewItem(cache, 1, true, false);
            ChatHandler(player->GetSession()).PSendSysMessage(
                "|cffffd700[Paragon]|r Daily |cff00ff00Cache of Synival's Treasures|r is ready!");
        }

        uint32 level, prestige, xp, bpts;
        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            level    = g_ParagonMap[guid].paragonLevel;
            prestige = g_ParagonMap[guid].prestigeCount;
            xp       = g_ParagonMap[guid].paragonXP;
            bpts     = g_ParagonMap[guid].boardPoints;
        }
        uint32 cap = GetCurrentCap(prestige);

        ChatHandler ch(player->GetSession());
        uint32 shards;
        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            shards = g_ParagonMap[guid].paragonShards;
        }

        // Build login status as a pre-formatted string to avoid
        // PSendSysMessage fmt-vs-printf ambiguity with color codes
        std::string loginLine =
            "|cffffd700[Paragon]|r "
            "Lv |cff00ff00" + std::to_string(level) + "|r/|cff00ff00" + std::to_string(cap) + "|r  "
            "XP |cff888888" + FormatLargeNumber(xp) + "/" + FormatLargeNumber(g_Config.XPPerParagonLevel) + "|r  "
            "Prestige |cffFF8000" + std::to_string(prestige) + "/" + std::to_string(g_Config.MaxPrestige) + "|r  "
            "Shards |cff00FF00" + std::to_string(shards) + "|r  "
            "Board Pts |cffFFD700" + std::to_string(bpts) + "|r";

        ch.SendSysMessage(loginLine.c_str());
        ch.SendSysMessage(
            "|cff888888[Paragon]|r Visit the |cffFF8000Runic Archive|r in Dalaran "
            "to manage your Paragon Board.");
    }

    // ── Logout: persist, clear runtime state ─────────────────────────────
    void OnPlayerLogout(Player* player) override
    {
        if (!g_Config.Enable) return;
        ClearBoardState(player);
    }

    // ── Item loot tagging + hidden affixes ────────────────────────────────
    void OnPlayerLootItem(Player* player, Item* item, uint32 /*count*/, ObjectGuid /*lootguid*/) override
    {
        if (!g_Config.Enable || !item) return;
        // Guard against a freed Item* reaching GetTemplate(). This is the exact
        // crash site from the recorded ACCESS_VIOLATION (Object::GetUInt32Value+3D,
        // RAX=0): an item destroyed by an earlier script in the same callback
        // chain has m_uint32Values = null; IsInWorld() catches it before we
        // dereference. Root cause is fixed (AutoStoreLoot removed in loot script),
        // but this guard stays as defence-in-depth.
        if (!item->IsInWorld()) return;
        ItemTemplate const* proto = item->GetTemplate();
        if (!proto) return;

        const char* tag = nullptr;
        switch (proto->Quality)
        {
            case ITEM_QUALITY_UNCOMMON:  tag = "|cff1eff00[Magic]|r";     break;
            case ITEM_QUALITY_RARE:      tag = "|cff0070dd[Rare]|r";      break;
            case ITEM_QUALITY_EPIC:      tag = "|cffa335ee[Epic]|r";      break;
            case ITEM_QUALITY_LEGENDARY: tag = "|cffff8000[Legendary]|r"; break;
            default: break;
        }
        if (tag)
            ChatHandler(player->GetSession()).PSendSysMessage(
                "|cffffd700[Paragon Loot]|r {} {}", tag, proto->Name1);

        if (proto->Quality >= ITEM_QUALITY_UNCOMMON
            && (proto->Class == ITEM_CLASS_WEAPON || proto->Class == ITEM_CLASS_ARMOR)
            && !HIDDEN_AFFIX_POOL.empty()
            && roll_chance_i(static_cast<int32>(g_Config.HiddenAffixChance)))
        {
            uint32 enchantId = Acore::Containers::SelectRandomContainerElement(HIDDEN_AFFIX_POOL);
            item->SetEnchantment(PERM_ENCHANTMENT_SLOT, enchantId, 0, 0);
            item->SetState(ITEM_CHANGED, player);
            ChatHandler(player->GetSession()).PSendSysMessage(
                "|cffffd700[Paragon Loot]|r |cffFFD700Hidden Affix|r rolled on {}!",
                proto->Name1);
        }
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Runic Archive gossip
//
// Gossip action encoding (see mod_paragon_board.h):
//   action = (pageType << 24) | (nodeId_12bit << 12) | secondary_12bit
//   sender = boardId  (or 0 for non-board pages)
//
// Board gossip pages added to existing menu:
//   ARCHIVE_BOARD_LIST   = 20
//   BGA_BOARD_OVERVIEW   arrives via IsBoardAction() → DecBoardAction()
//
// Existing Archive actions (1-10) are preserved unchanged.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// item_mark_of_ascension  (item entry 99300)
// ─────────────────────────────────────────────────────────────────────────────

class item_mark_of_ascension : public ItemScript
{
public:
    item_mark_of_ascension() : ItemScript("item_mark_of_ascension") {}

    bool OnUse(Player* player, Item* /*item*/, SpellCastTargets const& /*targets*/) override
    {
        if (!g_Config.Enable) return false;
        ObjectGuid guid = player->GetGUID();

        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            if (g_ParagonMap[guid].markUsed)
            {
                ChatHandler(player->GetSession()).SendSysMessage(
                    "|cffFF4444[Mark of the Ascended]|r Already applied. Cannot be used again.");
                return true;
            }
        }
        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            g_ParagonMap[guid].markUsed = true;
            SavePlayerData(guid, g_ParagonMap[guid]);
        }

        RefreshStatBonus(player);
        player->DestroyItemCount(g_Config.ItemMarkAscensionEntry, 1, true);
        player->AddAura(g_Config.SpellAscensionGlow, player);
        {
            std::ostringstream notifSS;
            notifSS << "Mark of the Ascended activated! +" << static_cast<uint32>(g_Config.MarkBonusPercent) << "% permanent stats.";
            std::string notifMsg = notifSS.str();
            WorldPacket notifData(SMSG_NOTIFICATION, notifMsg.size() + 1);
            notifData << notifMsg;
            player->GetSession()->SendPacket(&notifData);
        }
        ChatHandler(player->GetSession()).PSendSysMessage(
            "|cffffd700[Mark of the Ascended]|r |cff00ff00+{:.0f}%|r permanent stat bonus applied.",
            g_Config.MarkBonusPercent);
        return true;
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// npc_kadala_gamble  (NPC entry 99998)
// ─────────────────────────────────────────────────────────────────────────────

// Kadala shard bundle cost in copper (default 500g = 5,000,000 copper)
static constexpr uint32 KADALA_SHARD_BUNDLE_COST    = 5000000;
static constexpr uint32 KADALA_SHARD_BUNDLE_AMOUNT  = 100;
static constexpr uint32 PARAGON_SHARD_ITEM_ENTRY    = 99400;

enum KadalaActions
{
    KADALA_STANDARD     = 1,
    KADALA_PREMIUM      = 2,
    KADALA_BUY_SHARDS   = 3,
    KADALA_CLOSE        = 4,
};

class npc_kadala_gamble : public CreatureScript
{
public:
    npc_kadala_gamble() : CreatureScript("npc_kadala_gamble") {}

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ClearGossipMenuFor(player);

        AddGossipItemFor(player, GOSSIP_ICON_MONEY_BAG,
                         "Standard Roll  " + std::to_string(g_Config.KadalaCostStandard / 10000)
                         + "g  (Random Item)",
                         GOSSIP_SENDER_MAIN, KADALA_STANDARD);

        AddGossipItemFor(player, GOSSIP_ICON_MONEY_BAG,
                         "Premium Roll   " + std::to_string(g_Config.KadalaCostPremium / 10000)
                         + "g  (Rare+ Guaranteed)",
                         GOSSIP_SENDER_MAIN, KADALA_PREMIUM);

        // Paragon Shard bundle — show restock timer if on cooldown
        {
            ObjectGuid guid = player->GetGUID();
            uint32 today    = static_cast<uint32>(std::time(nullptr) / 86400);
            uint32 lastDay  = 0;
            {
                std::lock_guard<std::mutex> lock(g_ParagonMutex);
                auto it = g_ParagonMap.find(guid);
                if (it != g_ParagonMap.end())
                    lastDay = it->second.lastShardPurchaseDay;
            }

            if (lastDay < today)
            {
                AddGossipItemFor(player, GOSSIP_ICON_MONEY_BAG,
                                 "Buy Paragon Shards  500g  (x100 — daily limit)",
                                 GOSSIP_SENDER_MAIN, KADALA_BUY_SHARDS);
            }
            else
            {
                // Calculate hours remaining until midnight UTC reset
                uint32 nowSecs      = static_cast<uint32>(std::time(nullptr));
                uint32 nextDaySecs  = (today + 1) * 86400;
                uint32 hoursLeft    = (nextDaySecs - nowSecs) / 3600 + 1;
                AddGossipItemFor(player, GOSSIP_ICON_CHAT,
                                 "Paragon Shards — restocks in ~"
                                 + std::to_string(hoursLeft) + "h  (daily limit reached)",
                                 GOSSIP_SENDER_MAIN, KADALA_CLOSE);
            }
        }

        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Farewell.", GOSSIP_SENDER_MAIN, KADALA_CLOSE);
        SendGossipMenuFor(player, 99998, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* /*creature*/,
                        uint32 /*sender*/, uint32 action) override
    {
        CloseGossipMenuFor(player);
        if (action == KADALA_CLOSE) return true;

        // ── Paragon Shard bundle purchase ─────────────────────────────────
        if (action == KADALA_BUY_SHARDS)
        {
            ObjectGuid guid  = player->GetGUID();
            uint32 today     = static_cast<uint32>(std::time(nullptr) / 86400);
            uint32 lastDay   = 0;
            {
                std::lock_guard<std::mutex> lock(g_ParagonMutex);
                auto it = g_ParagonMap.find(guid);
                if (it != g_ParagonMap.end())
                    lastDay = it->second.lastShardPurchaseDay;
            }

            // Double-check: still available today?
            if (lastDay >= today)
            {
                ChatHandler(player->GetSession()).SendSysMessage(
                    "|cffFF4444[Kadala]|r Daily shard bundle already purchased.");
                return true;
            }

            // Gold check: 500g = 5,000,000 copper
            if (!player->HasEnoughMoney(static_cast<int32>(KADALA_SHARD_BUNDLE_COST)))
            {
                ChatHandler(player->GetSession()).PSendSysMessage(
                    "|cffFF4444[Kadala]|r Not enough gold. Cost: |cffffd700500g|r.");
                return true;
            }

            player->ModifyMoney(-static_cast<int32>(KADALA_SHARD_BUNDLE_COST));

            // Record the purchase day and award shards
            uint32 newShards;
            {
                std::lock_guard<std::mutex> lock(g_ParagonMutex);
                ParagonData& d         = g_ParagonMap[guid];
                d.lastShardPurchaseDay = today;
                d.paragonShards       += KADALA_SHARD_BUNDLE_AMOUNT;
                newShards              = d.paragonShards;
            }
            SaveShardsOnly(guid, newShards,  today);

            // Give the item to the player's bags as well
            ItemPosCountVec dest;
            if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, PARAGON_SHARD_ITEM_ENTRY,
                                        KADALA_SHARD_BUNDLE_AMOUNT) == EQUIP_ERR_OK)
            {
                if (Item* shards = player->StoreNewItem(dest, PARAGON_SHARD_ITEM_ENTRY, true))
                    player->SendNewItem(shards, KADALA_SHARD_BUNDLE_AMOUNT, true, false);
            }

            ChatHandler(player->GetSession()).PSendSysMessage(
                "|cffFFD700[Kadala]|r +|cff00FF00{}|r Paragon Shards purchased. "
                "Total: |cff00FF00{}|r. Next purchase available tomorrow.",
                KADALA_SHARD_BUNDLE_AMOUNT, newShards);
            return true;
        }

        // ── Item rolls (Standard / Premium) ──────────────────────────────
        bool   premium = (action == KADALA_PREMIUM);
        uint32 cost    = premium ? g_Config.KadalaCostPremium : g_Config.KadalaCostStandard;

        if (!player->HasEnoughMoney(static_cast<int32>(cost)))
        {
            ChatHandler(player->GetSession()).PSendSysMessage(
                "|cffFF4444[Kadala]|r Not enough gold. Cost: |cffffd700{}g|r.", cost / 10000);
            return true;
        }
        player->ModifyMoney(-static_cast<int32>(cost));

        auto const& pool = premium ? KADALA_POOL_PREMIUM : KADALA_POOL_STANDARD;
        if (pool.empty())
        {
            player->ModifyMoney(static_cast<int32>(cost));
            ChatHandler(player->GetSession()).SendSysMessage(
                "|cffFF4444[Kadala]|r Pool not configured. Refunded.");
            return true;
        }

        uint32 entry = Acore::Containers::SelectRandomContainerElement(pool);
        ItemPosCountVec dest;
        if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, entry, 1) == EQUIP_ERR_OK)
        {
            if (Item* item = player->StoreNewItem(dest, entry, true))
                player->SendNewItem(item, 1, true, false);
        }
        else
        {
            player->ModifyMoney(static_cast<int32>(cost));
            ChatHandler(player->GetSession()).SendSysMessage(
                "|cffFF4444[Kadala]|r Inventory full. Refunded.");
        }
        return true;
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// CommandScript
//
// Command fix notes
// ──────────────────
//   All admin handlers guard GetSession() against null before calling
//   GetSecurity() — they were already doing the null-short-circuit pattern
//   (if session && security < SEC_ADMIN) which is correct for console.
//
//   getSelectedPlayer() replaced with getSelectedPlayerOrSelf() so that a GM
//   standing alone can target themselves without an explicit selection.
//
//   HandleSetPrestigeRank used getSelectedPlayer() (not *OrSelf) — fixed.
//
//   HandleKadalaTeleport called GetSession()->GetPlayer() without first
//   confirming the session is non-null. Fixed with an explicit session guard
//   and an informative console-rejection message.
// ─────────────────────────────────────────────────────────────────────────────

class SynivalParagonCommandScript : public CommandScript
{
public:
    SynivalParagonCommandScript() : CommandScript("SynivalParagonCommandScript") {}

    Acore::ChatCommands::ChatCommandTable GetCommands() const override
    {
        using namespace Acore::ChatCommands;

        static ChatCommandTable glyphTable =
        {
            { "socket", HandleBoardGlyphSocket, SEC_PLAYER, Console::No },
            { "remove", HandleBoardGlyphRemove, SEC_PLAYER, Console::No },
        };

        static ChatCommandTable boardTable =
        {
            { "list",   HandleBoardList,   SEC_PLAYER, Console::No },
            { "info",   HandleBoardInfo,   SEC_PLAYER, Console::No },
            { "nodes",  HandleBoardNodes,  SEC_PLAYER, Console::No },
            { "unlock", HandleBoardUnlock, SEC_PLAYER, Console::No },
            { "glyph",  glyphTable                                        },
        };

        static ChatCommandTable adminTable =
        {
            { "addpoints",  HandleAdminAddPoints,  SEC_ADMINISTRATOR, Console::No },
            { "resetboard", HandleAdminResetBoard, SEC_ADMINISTRATOR, Console::No },
        };

        static ChatCommandTable setTable =
        {
            { "level",    HandleSetParagonLevel, SEC_ADMINISTRATOR, Console::No },
            { "prestige", HandleSetPrestigeRank, SEC_ADMINISTRATOR, Console::No },
        };

        static ChatCommandTable paragonTable =
        {
            { "board",  boardTable                                        },
            { "points", HandleParagonPoints,   SEC_PLAYER,        Console::No },
            { "status", HandleParagonStatus,   SEC_PLAYER,        Console::No },
            { "set",    setTable                                          },
            { "admin",  adminTable                                        },
            { "kadala", HandleKadalaTeleport,  SEC_ADMINISTRATOR, Console::No },
        };

        static ChatCommandTable rootTable =
        {
            { "paragon", paragonTable },
        };
        return rootTable;
    }

    // ── .paragon board list ───────────────────────────────────────────────
    static bool HandleBoardList(ChatHandler* handler, std::string_view /*args*/)
    {
        Player* player = handler->GetSession()->GetPlayer();
        if (!player) return true;

        ObjectGuid guid = player->GetGUID();
        uint32 pLevel, prestige;
        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            pLevel   = g_ParagonMap[guid].paragonLevel;
            prestige = g_ParagonMap[guid].prestigeCount;
        }

        handler->SendSysMessage("|cffFFD700=== Paragon Boards ===|r");
        for (auto const& board : g_Boards)
        {
            bool visible = IsBoardVisibleForPlayer(player, board, pLevel, prestige);
            std::string status = visible ? "|cff00FF00[UNLOCKED]|r" : "|cff666666[LOCKED]|r";
            handler->PSendSysMessage("  [{}] {}  {}", board.boardId, board.name, status);
        }
        return true;
    }

    // ── .paragon board info <id> ──────────────────────────────────────────
    static bool HandleBoardInfo(ChatHandler* handler, std::string_view args)
    {
        if (args.empty()) { handler->SendSysMessage("Usage: .paragon board info <board_id>"); return true; }
        auto opt = Acore::StringTo<uint8>(args);
        if (!opt) { handler->PSendSysMessage("Invalid board ID."); return true; }

        ParagonBoardDef const* board = FindBoard(*opt);
        if (!board) { handler->PSendSysMessage("Board {} not found.", *opt); return true; }

        handler->PSendSysMessage("|cffFFD700Board {}: {}|r", board->boardId, board->name);
        handler->PSendSysMessage("  Nodes: {}   Size: {}x{}",
            board->nodes.size(), board->width, board->height);
        handler->PSendSysMessage("  Unlocks at Paragon {}, Prestige {}",
            board->unlockParagonLevel, board->unlockPrestige);

        uint32 norm = 0, magic = 0, rare = 0, socket = 0;
        for (auto const& n : board->nodes)
            switch (n.type)
            {
                case NODE_NORMAL: ++norm;   break;
                case NODE_MAGIC:  ++magic;  break;
                case NODE_RARE:   ++rare;   break;
                case NODE_SOCKET: ++socket; break;
                default: break;
            }
        handler->PSendSysMessage("  Normal:{}  Magic:{}  Rare:{}  Socket:{}",
            norm, magic, rare, socket);
        return true;
    }

    // ── .paragon board nodes <id> ─────────────────────────────────────────
    static bool HandleBoardNodes(ChatHandler* handler, std::string_view args)
    {
        if (args.empty()) { handler->SendSysMessage("Usage: .paragon board nodes <board_id>"); return true; }
        auto opt = Acore::StringTo<uint8>(args);
        if (!opt) return true;

        ParagonBoardDef const* board = FindBoard(*opt);
        if (!board) { handler->PSendSysMessage("Board {} not found.", *opt); return true; }

        Player* player = handler->GetSession()->GetPlayer();
        if (!player) return true;
        ObjectGuid guid = player->GetGUID();
        PlayerBoardState stateCopy;
        uint32 boardPoints;
        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            boardPoints = g_ParagonMap[guid].boardPoints;
            auto pit = g_PlayerBoardStates.find(guid);
            if (pit != g_PlayerBoardStates.end())
            {
                auto bit = pit->second.find(*opt);
                if (bit != pit->second.end()) stateCopy = bit->second;
            }
        }

        handler->PSendSysMessage("|cffFFD700{} — Nodes (Points: {})|r",
            board->name, boardPoints);
        for (auto const& node : board->nodes)
        {
            if (node.type == NODE_START) continue;
            bool unlocked   = stateCopy.unlockedNodes.count(node.nodeId) > 0;
            bool adjacent   = IsNodeAdjacent(*board, stateCopy, node.nodeId);
            bool affordable = (boardPoints >= NODE_COSTS[static_cast<uint8>(node.type)]);
            handler->PSendSysMessage("  [{}] {}",
                node.nodeId,
                FormatNodeEntry(node, unlocked, adjacent, affordable));
        }
        return true;
    }

    // ── .paragon board unlock <board_id> <node_id> ────────────────────────
    static bool HandleBoardUnlock(ChatHandler* handler, std::string_view args)
    {
        if (args.empty()) { handler->SendSysMessage("Usage: .paragon board unlock <board_id> <node_id>"); return true; }
        std::string argsStr{args.begin(), args.end()};
        std::istringstream ss{argsStr};
        uint32 bRaw = 0, nRaw = 0;
        ss >> bRaw >> nRaw;
        if (!bRaw || !nRaw) { handler->SendSysMessage("Usage: .paragon board unlock <board_id> <node_id>"); return true; }

        Player* player = handler->GetSession()->GetPlayer();
        if (!player) return true;

        if (UnlockNode(player, static_cast<uint8>(bRaw), static_cast<uint16>(nRaw)))
            handler->PSendSysMessage("|cff00FF00[Paragon Board]|r Node {} on board {} unlocked.", nRaw, bRaw);
        else
            handler->PSendSysMessage("|cffFF4444[Paragon Board]|r Cannot unlock node {} on board {}. "
                "Check adjacency, points, and ownership.", nRaw, bRaw);
        return true;
    }

    // ── .paragon board glyph socket <board_id> <node_id> <glyph_id> ──────
    static bool HandleBoardGlyphSocket(ChatHandler* handler, std::string_view args)
    {
        if (args.empty()) { handler->SendSysMessage("Usage: .paragon board glyph socket <board_id> <node_id> <glyph_id>"); return true; }
        std::string argsStr{args.begin(), args.end()};
        std::istringstream ss{argsStr};
        uint32 bRaw = 0, nRaw = 0, gRaw = 0;
        ss >> bRaw >> nRaw >> gRaw;
        if (!bRaw || !nRaw || !gRaw) return true;

        Player* player = handler->GetSession()->GetPlayer();
        if (!player) return true;

        if (SocketGlyph(player, static_cast<uint8>(bRaw), static_cast<uint16>(nRaw), static_cast<uint16>(gRaw)))
            handler->PSendSysMessage("|cff00FF00[Paragon Board]|r Glyph socketed.");
        else
            handler->PSendSysMessage("|cffFF4444[Paragon Board]|r Could not socket glyph. "
                "Check: node is unlocked, node is SOCKET type, glyph in bags, slot is empty.");
        return true;
    }

    // ── .paragon board glyph remove <board_id> <node_id> ─────────────────
    static bool HandleBoardGlyphRemove(ChatHandler* handler, std::string_view args)
    {
        if (args.empty()) { handler->SendSysMessage("Usage: .paragon board glyph remove <board_id> <node_id>"); return true; }
        std::string argsStr{args.begin(), args.end()};
        std::istringstream ss{argsStr};
        uint32 bRaw = 0, nRaw = 0;
        ss >> bRaw >> nRaw;
        if (!bRaw || !nRaw) return true;

        Player* player = handler->GetSession()->GetPlayer();
        if (!player) return true;

        if (RemoveGlyph(player, static_cast<uint8>(bRaw), static_cast<uint16>(nRaw)))
            handler->PSendSysMessage("|cff00FF00[Paragon Board]|r Glyph removed and returned to bags.");
        else
            handler->PSendSysMessage("|cffFF4444[Paragon Board]|r No glyph found in that socket.");
        return true;
    }

    // ── .paragon points ───────────────────────────────────────────────────
    static bool HandleParagonPoints(ChatHandler* handler, std::string_view /*args*/)
    {
        Player* player = handler->GetSession()->GetPlayer();
        if (!player) return true;
        ObjectGuid guid = player->GetGUID();
        uint32 bpts;
        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            bpts = g_ParagonMap[guid].boardPoints;
        }
        handler->PSendSysMessage(
            "|cffFFD700[Paragon Board]|r You have |cff00FF00{}|r Board Point{} available.",
            bpts, bpts == 1 ? "" : "s");
        return true;
    }

    // ── .paragon status ───────────────────────────────────────────────────
    static bool HandleParagonStatus(ChatHandler* handler, std::string_view /*args*/)
    {
        Player* player = handler->GetSession()->GetPlayer();
        if (!player) return true;
        ObjectGuid guid = player->GetGUID();
        uint32 level, prestige, xp, bpts;
        bool   markUsed;
        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            ParagonData& d = g_ParagonMap[guid];
            level    = d.paragonLevel; prestige = d.prestigeCount;
            xp       = d.paragonXP;   bpts     = d.boardPoints;
            markUsed = d.markUsed;
        }
        uint32 cap = GetCurrentCap(prestige);

        handler->PSendSysMessage("|cffffd700==== Paragon Status ====|r");
        handler->PSendSysMessage("|cffffd700Level:|r    |cff00ff00{}|r/|cff00ff00{}|r  {}",
            level, cap, BuildProgressBar(level, cap, 14));
        handler->PSendSysMessage("|cffffd700XP:|r      {}  |cff888888{}|r/|cff888888{}|r",
            BuildProgressBar(xp, g_Config.XPPerParagonLevel, 14),
            FormatLargeNumber(xp), FormatLargeNumber(g_Config.XPPerParagonLevel));
        handler->PSendSysMessage("|cffffd700Prestige:|r {}",
            BuildPrestigeStars(prestige, g_Config.MaxPrestige));
        handler->PSendSysMessage("|cffffd700Stat Bonus:|r |cff00ff00+{:.0f}%|r{}",
            std::min(static_cast<float>(level) * g_Config.StatBonusPerLevel, g_Config.StatBonusCap),
            markUsed ? "  |cffffd700+15% (Mark)|r" : "");
        handler->PSendSysMessage("|cffffd700Board Points:|r |cffFFD700{}|r", bpts);
        return true;
    }

    // ── .paragon admin addpoints <amount> ─────────────────────────────────
    static bool HandleAdminAddPoints(ChatHandler* handler, std::string_view args)
    {
        if (handler->GetSession() && handler->GetSession()->GetSecurity() < SEC_ADMINISTRATOR)
        { handler->SendSysMessage("|cffFF4444You do not have permission to use this command.|r"); return true; }
        if (args.empty()) { handler->SendSysMessage("Usage: .paragon admin addpoints <amount>"); return true; }
        auto opt = Acore::StringTo<uint32>(args);
        if (!opt) { handler->PSendSysMessage("Invalid amount."); return true; }

        Player* target = handler->getSelectedPlayerOrSelf();
        if (!target) { handler->SendSysMessage("No player selected or found."); return true; }

        ObjectGuid guid = target->GetGUID();
        uint32 newPts;
        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            g_ParagonMap[guid].boardPoints += *opt;
            newPts = g_ParagonMap[guid].boardPoints;
        }
        SaveBoardPointsOnly(guid, newPts);
        handler->PSendSysMessage("Added {} Board Points to {} (total: {}).",
            *opt, target->GetName(), newPts);
        if (target->GetSession())
            ChatHandler(target->GetSession()).PSendSysMessage(
                "|cffFFD700[Paragon Board]|r An admin granted you |cff00FF00{}|r Board Points. Total: {}.",
                *opt, newPts);
        return true;
    }

    // ── .paragon admin resetboard <board_id> ─────────────────────────────
    static bool HandleAdminResetBoard(ChatHandler* handler, std::string_view args)
    {
        if (handler->GetSession() && handler->GetSession()->GetSecurity() < SEC_ADMINISTRATOR)
        { handler->SendSysMessage("|cffFF4444You do not have permission to use this command.|r"); return true; }
        if (args.empty()) { handler->SendSysMessage("Usage: .paragon admin resetboard <board_id>"); return true; }
        auto opt = Acore::StringTo<uint8>(args);
        if (!opt) return true;

        Player* target = handler->getSelectedPlayerOrSelf();
        if (!target) { handler->SendSysMessage("No player selected or found."); return true; }

        ParagonBoardDef const* board = FindBoard(*opt);
        if (!board) { handler->PSendSysMessage("Board {} not found.", *opt); return true; }

        ObjectGuid guid = target->GetGUID();
        uint32 refundPts = 0;
        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            auto& state = g_PlayerBoardStates[guid][*opt];
            for (uint16 nodeId : state.unlockedNodes)
            {
                ParagonNodeDef const* node = board->GetNode(nodeId);
                if (node) refundPts += NODE_COSTS[static_cast<uint8>(node->type)];
            }
            state.unlockedNodes.clear();
            state.socketedGlyphs.clear();
            g_ParagonMap[guid].boardPoints += refundPts;
        }

        CharacterDatabase.Execute(
            "DELETE FROM character_paragon_nodes WHERE guid = {} AND board_id = {}",
            guid.GetCounter(), *opt);
        CharacterDatabase.Execute(
            "DELETE FROM character_paragon_glyphs WHERE guid = {} AND board_id = {}",
            guid.GetCounter(), *opt);

        uint32 newPts;
        { std::lock_guard<std::mutex> lock(g_ParagonMutex); newPts = g_ParagonMap[guid].boardPoints; }
        SaveBoardPointsOnly(guid, newPts);
        ApplyAllBoardStats(target, false);
        ApplyAllBoardStats(target, true);

        handler->PSendSysMessage("Board {} reset for {}. Refunded {} points (total: {}).",
            *opt, target->GetName(), refundPts, newPts);
        if (target->GetSession())
            ChatHandler(target->GetSession()).PSendSysMessage(
                "|cffFFD700[Paragon Board]|r Board '{}' has been reset. "
                "{} points refunded (total: {}).",
                board->name, refundPts, newPts);
        return true;
    }

    // ── .paragon set level <value> ────────────────────────────────────────
    static bool HandleSetParagonLevel(ChatHandler* handler, std::string_view args)
    {
        if (handler->GetSession() && handler->GetSession()->GetSecurity() < SEC_ADMINISTRATOR)
        { handler->SendSysMessage("|cffFF4444You do not have permission to use this command.|r"); return true; }
        if (args.empty()) { handler->SendSysMessage("Usage: .paragon set level <value>"); return true; }
        auto opt = Acore::StringTo<uint32>(args);
        if (!opt) return true;
        Player* target = handler->getSelectedPlayerOrSelf();
        if (!target) { handler->SendSysMessage("No player selected or found."); return true; }
        ObjectGuid guid = target->GetGUID();
        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            g_ParagonMap[guid].paragonLevel = *opt;
            SavePlayerData(guid, g_ParagonMap[guid]);
        }
        RefreshStatBonus(target);
        handler->PSendSysMessage("Paragon Level for {} set to {}.", target->GetName(), *opt);
        return true;
    }

    // ── .paragon set prestige <value> ────────────────────────────────────
    static bool HandleSetPrestigeRank(ChatHandler* handler, std::string_view args)
    {
        if (handler->GetSession() && handler->GetSession()->GetSecurity() < SEC_ADMINISTRATOR)
        { handler->SendSysMessage("|cffFF4444You do not have permission to use this command.|r"); return true; }
        if (args.empty()) { handler->SendSysMessage("Usage: .paragon set prestige <value>"); return true; }
        auto opt = Acore::StringTo<uint32>(args);
        if (!opt) return true;
        // FIX: was getSelectedPlayer() — now getSelectedPlayerOrSelf() so a
        // GM can target themselves without an explicit selection.
        Player* target = handler->getSelectedPlayerOrSelf();
        if (!target) { handler->SendSysMessage("No player selected or found."); return true; }
        ObjectGuid guid = target->GetGUID();
        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            g_ParagonMap[guid].prestigeCount = *opt;
            SavePlayerData(guid, g_ParagonMap[guid]);
        }
        handler->PSendSysMessage("Prestige Rank for {} set to {}.", target->GetName(), *opt);
        return true;
    }

    // ── .paragon kadala ───────────────────────────────────────────────────
    static bool HandleKadalaTeleport(ChatHandler* handler, std::string_view /*args*/)
    {
        if (handler->GetSession() && handler->GetSession()->GetSecurity() < SEC_ADMINISTRATOR)
        { handler->SendSysMessage("|cffFF4444You do not have permission to use this command.|r"); return true; }
        // FIX: GetSession() can be null when called from the server console.
        // Guard before dereferencing, and return an informative message.
        if (!handler->GetSession())
        { handler->SendSysMessage("This command requires an active in-game session."); return true; }
        Player* player = handler->GetSession()->GetPlayer();
        if (!player) return true;
        player->TeleportTo(571, 5724.31f, 761.10f, 641.40f, 3.14f);
        return true;
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// item_cache_of_synival  (item entry 99200)
//
// Daily login reward. On right-click:
//   • Awards a guaranteed Paragon Shard item bundle (urand CacheShardMin–CacheShardMax)
//   • Queries the world DB for a random weapon/armor/ring/trinket/neck of the
//     rolled quality tier from the player's level range, then gives it
//   • Quality roll (default): Rare = 70%, Epic = 25%, Legendary = 5%
//   • The shard count is also forwarded to ModifyPlayerParagonShards() so
//     Kadala and the Legendary Vendor always see the correct total
// ─────────────────────────────────────────────────────────────────────────────

class item_cache_of_synival : public ItemScript
{
public:
    item_cache_of_synival() : ItemScript("item_cache_of_synival") {}

    bool OnUse(Player* player, Item* item, SpellCastTargets const& /*targets*/) override
    {
        if (!g_Config.Enable) return false;

        ChatHandler ch(player->GetSession());

        // ── 1. Roll quality tier ──────────────────────────────────────────
        // Clamp chances so they never exceed 100 combined
        uint32 legendaryChance = g_Config.CacheLegendaryChance;
        uint32 epicChance      = g_Config.CacheEpicChance;
        if (legendaryChance + epicChance > 100)
            epicChance = 100 - legendaryChance;

        uint32 roll    = urand(1, 100);
        uint32 quality = ITEM_QUALITY_RARE;  // default: Rare
        if (roll <= legendaryChance)
            quality = ITEM_QUALITY_LEGENDARY;
        else if (roll <= legendaryChance + epicChance)
            quality = ITEM_QUALITY_EPIC;

        static const char* QUALITY_TAGS[] = {
            "",                          // 0 Poor
            "",                          // 1 Common
            "",                          // 2 Uncommon
            "|cff0070dd[Rare]|r",        // 3 Rare
            "|cffa335ee[Epic]|r",        // 4 Epic
            "|cffff8000[Legendary]|r",   // 5 Legendary
        };

        // ── 2. Pick a random piece of equipment from the world DB ─────────
        // Eligible slots: weapon (1H/2H/staff/bow/off-hand), armor (head/
        // chest/legs/hands/feet/shoulders/waist/wrist/cloak), ring, trinket, neck.
        // We query items within ±10 item levels of the player's gear level (80)
        // and restrict to the rolled quality so the player always gets something
        // meaningful. The RAND() + LIMIT 1 approach is intentionally simple —
        // it works correctly for custom item ranges.
        uint32 itemEntry = 0;
        {
            QueryResult result = WorldDatabase.Query(
                "SELECT entry FROM item_template "
                "WHERE Quality = {} "
                "  AND RequiredLevel <= 80 "
                "  AND ItemLevel BETWEEN 200 AND 284 "
                "  AND class IN (2, 4) "  // ITEM_CLASS_WEAPON=2, ITEM_CLASS_ARMOR=4
                "  AND AllowableClass & {} "
                "ORDER BY RAND() LIMIT 1",
                quality,
                static_cast<uint32>(player->getClassMask()));

            if (result)
                itemEntry = result->Fetch()[0].Get<uint32>();
        }

        // Fallback: if the query returns nothing (e.g. custom server has no
        // matching items), drop to Rare and try a class-unrestricted query
        if (!itemEntry)
        {
            quality = ITEM_QUALITY_RARE;
            QueryResult result = WorldDatabase.Query(
                "SELECT entry FROM item_template "
                "WHERE Quality = {} "
                "  AND RequiredLevel <= 80 "
                "  AND ItemLevel BETWEEN 200 AND 284 "
                "  AND class IN (2, 4) "
                "ORDER BY RAND() LIMIT 1",
                quality);
            if (result)
                itemEntry = result->Fetch()[0].Get<uint32>();
        }

        // ── 3. Award shards ───────────────────────────────────────────────
        uint32 shardCount = urand(g_Config.CacheShardMin, g_Config.CacheShardMax);
        uint32 newShards  = ModifyPlayerParagonShards(player->GetGUID(),
                                static_cast<int32>(shardCount));

        ItemPosCountVec shardDest;
        if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, shardDest,
                                    PARAGON_SHARD_ITEM_ENTRY, shardCount) == EQUIP_ERR_OK)
        {
            if (Item* shards = player->StoreNewItem(shardDest, PARAGON_SHARD_ITEM_ENTRY, true))
                player->SendNewItem(shards, shardCount, false, true);
        }

        // ── 4. Award equipment ────────────────────────────────────────────
        if (itemEntry)
        {
            ItemPosCountVec eqDest;
            if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, eqDest, itemEntry, 1) == EQUIP_ERR_OK)
            {
                if (Item* eq = player->StoreNewItem(eqDest, itemEntry, true))
                {
                    player->SendNewItem(eq, 1, false, true);
                    uint32 q = eq->GetTemplate()->Quality;
                    const char* qtag = (q < 6) ? QUALITY_TAGS[q] : "";
                    ch.PSendSysMessage(
                        "|cffFFD700[Cache of Synival's Treasures]|r "
                        "Opened! Received |cff00FF00{}|r Paragon Shards (total: {}) "
                        "and {} {}.",
                        shardCount, newShards,
                        qtag, eq->GetTemplate()->Name1);
                }
            }
            else
            {
                // Bags full — inform player, shards were still awarded
                ch.PSendSysMessage(
                    "|cffFF4444[Cache]|r Bags full — equipment could not be added. "
                    "Received |cff00FF00{}|r Paragon Shards (total: {}).",
                    shardCount, newShards);
            }
        }
        else
        {
            // No equipment found — shards only
            ch.PSendSysMessage(
                "|cffFFD700[Cache of Synival's Treasures]|r "
                "Opened! Received |cff00FF00{}|r Paragon Shards (total: {}).",
                shardCount, newShards);
        }

        // ── 5. Consume the cache item ─────────────────────────────────────
        player->DestroyItem(item->GetBagSlot(), item->GetSlot(), true);
        return true;
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// npc_runic_archive_statsync
//
// Lightweight CreatureScript for NPC 99996 (Runic Archive).
// All gossip menu rendering is handled by the Eluna Lua script
// (synparagon_board.lua) which runs as the sole gossip handler.
//
// This script does NOT render any gossip menus. Its only purpose is to
// intercept node-unlock and glyph socket/remove gossip actions AFTER Lua
// has written the result to the character DB, and then reload the C++
// in-memory g_PlayerBoardStates + reapply stat bonuses so the player's
// stats reflect their new nodes immediately without requiring a relog.
//
// Why this is safe alongside the Lua script:
//   • Eluna gossip wrapper fires first and sends the gossip menu.
//   • This CreatureScript fires second.
//   • It only calls LoadBoardState + RefreshStatBonus — never SendGossipMenuFor.
//   • Returning true suppresses the default gossip (correct — Lua already
//     sent the menu; we don't want a second one).
// ─────────────────────────────────────────────────────────────────────────────

class npc_runic_archive_statsync : public CreatureScript
{
public:
    npc_runic_archive_statsync() : CreatureScript("npc_runic_archive_statsync") {}

    bool OnGossipSelect(Player* player, Creature* /*creature*/,
                        uint32 /*sender*/, uint32 action) override
    {
        if (!g_Config.Enable) return false;
        if (!IsBoardAction(action)) return false;

        uint8  page;
        uint16 nodeId, secondary;
        DecBoardAction(action, page, nodeId, secondary);

        // Only act on mutations that change board state in the DB.
        // BGA_NODE_UNLOCK, BGA_GLYPH_SOCKET, BGA_GLYPH_REMOVE all
        // have Lua handlers that write to character_paragon_nodes /
        // character_paragon_glyphs before this fires.
        if (page != BGA_NODE_UNLOCK  &&
            page != BGA_GLYPH_SOCKET &&
            page != BGA_GLYPH_REMOVE)
            return false;

        // Reload board state from DB into C++ memory, then reapply stats.
        // This runs after Lua's CharDBExecute has completed the DB write.
        LoadBoardState(player);
        RefreshStatBonus(player);
        return false;   // false = don't suppress default; Lua already sent menu
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Old-World Flying
//
// Grants players the MOVEMENTFLAG_CAN_FLY flag on Eastern Kingdoms (map 0)
// and Kalimdor (map 1) when they possess the World Flight Mastery spell
// (OldWorldFlying.SpellId, default 200010), or unconditionally when
// OldWorldFlying.AllPlayersFly = 1.
//
// Blizzard's IsKnowHowFlyIn() hardcodes a refusal for maps 0 and 1.
// This module bypasses that refusal via SetCanFly(), which is the same
// mechanism the core uses for GM flight — authoritative, not cosmetic.
//
// The client-side AreaTable.dbc must also be patched (provided separately)
// to prevent the mount button from going grey, which is the UI's way of
// expressing institutional disappointment.
//
// SQL dependencies:
//   data/sql/world/base/01_world_flight_spell.sql     — spell_dbc entry
//   data/sql/characters/base/01_grant_world_flight.sql — grant to players
// ─────────────────────────────────────────────────────────────────────────────

static bool IsOldWorldMap(uint32 mapId)
{
    return mapId == 0 || mapId == 1;  // 0 = Eastern Kingdoms, 1 = Kalimdor
}

static bool PlayerCanFlyOldWorld(Player* player)
{
    if (!player)
        return false;
    if (g_Config.OldWorldFlyingAllFly)
        return true;
    return player->HasSpell(g_Config.OldWorldFlyingSpellId);
}

static void ApplyOldWorldFlying(Player* player)
{
    if (!player || !player->IsInWorld())
        return;

    if (IsOldWorldMap(player->GetMapId()) && PlayerCanFlyOldWorld(player))
    {
        if (!player->HasUnitMovementFlag(MOVEMENTFLAG_CAN_FLY))
        {
            player->SetCanFly(true);
            player->SetWaterWalking(false);
        }
    }
}

class OldWorldFlyingPlayerScript : public PlayerScript
{
public:
    OldWorldFlyingPlayerScript() : PlayerScript("OldWorldFlyingPlayerScript") {}

    void OnPlayerLogin(Player* player, bool /*firstLogin*/) override
    {
        ApplyOldWorldFlying(player);
    }

    void OnPlayerUpdateZone(Player* player, uint32 /*newZone*/, uint32 /*newArea*/) override
    {
        ApplyOldWorldFlying(player);
    }

    void OnPlayerLearnSpell(Player* player, uint32 spellId) override
    {
        if (spellId == g_Config.OldWorldFlyingSpellId &&
            IsOldWorldMap(player->GetMapId()))
            ApplyOldWorldFlying(player);
    }

    void OnPlayerForgotSpell(Player* player, uint32 spellId) override
    {
        if (spellId == g_Config.OldWorldFlyingSpellId &&
            IsOldWorldMap(player->GetMapId()))
        {
            if (player->HasUnitMovementFlag(MOVEMENTFLAG_FLYING))
            {
                LOG_INFO("module",
                    "mod-synival-paragon: Player {} lost World Flight Mastery "
                    "while airborne on old-world map {}. Gravity resumes at next landing.",
                    player->GetName(), player->GetMapId());
            }
            player->SetCanFly(false);
        }
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// Village Periodic Reward bridge — defined here so it shares the TU with all
// static helpers (HandleParagonLevelUp, SavePlayerData, RefreshStatBonus).
// Declared in mod_paragon_board.h.
// ─────────────────────────────────────────────────────────────────────────────

void OtR_GrantParagonProgress(Player* player, bool fullLevel, uint32 boardPointsToAdd)
{
    if (!player)
        return;

    ObjectGuid guid = player->GetGUID();

    if (fullLevel)
    {
        // Determine current cap mirrors the cap logic used elsewhere in this file.
        uint32 maxPrestige = g_Config.MaxPrestige;
        uint32 baseCap     = g_Config.BaseParagonCap;
        uint32 extCap      = g_Config.ExtendedParagonCap;

        uint32 cap = 0;
        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            auto it = g_ParagonMap.find(guid);
            if (it == g_ParagonMap.end())
                return;

            cap = (it->second.prestigeCount >= maxPrestige) ? extCap : baseCap;

            if (it->second.paragonLevel >= cap)
            {
                // Already at cap — fall through to board points instead.
                it->second.boardPoints += boardPointsToAdd;
                SaveBoardPointsOnly(guid, it->second.boardPoints);
                return;
            }

            // Inject exactly one level's worth of XP.
            it->second.paragonXP += g_Config.XPPerParagonLevel;
            while (it->second.paragonXP >= g_Config.XPPerParagonLevel
                   && it->second.paragonLevel < cap)
            {
                it->second.paragonXP   -= g_Config.XPPerParagonLevel;
                it->second.paragonLevel++;
            }

            // Persist via the full save path so paragon_level and paragon_xp
            // are both written atomically.
            SavePlayerData(guid, it->second);
        }

        // HandleParagonLevelUp acquires g_ParagonMutex internally — must be
        // called outside the lock scope above.
        HandleParagonLevelUp(player);
    }
    else
    {
        std::lock_guard<std::mutex> lock(g_ParagonMutex);
        auto it = g_ParagonMap.find(guid);
        if (it == g_ParagonMap.end())
            return;

        it->second.boardPoints += boardPointsToAdd;
        SaveBoardPointsOnly(guid, it->second.boardPoints);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Script Registration
// ─────────────────────────────────────────────────────────────────────────────

void AddSC_mod_synival_paragon()
{
    new SynivalParagonWorldScript();
    new SynivalParagonPlayerScript();
    new OldWorldFlyingPlayerScript();
    new item_mark_of_ascension();
    new item_cache_of_synival();
    new npc_kadala_gamble();
    new SynivalParagonCommandScript();
    new npc_runic_archive_statsync();
}
