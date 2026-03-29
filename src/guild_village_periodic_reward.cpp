/*
 * guild_village_periodic_reward.cpp
 * Synival's Ode to Ramza
 *
 * Awards players a bundle of three rewards every 3 hours of server uptime,
 * provided they are inside their guild's village phase when the tick fires.
 *
 * Reward bundle (three independent rolls per tick):
 *
 *   1. Gold
 *      A random amount between GuildVillage.Reward.GoldMin and
 *      GuildVillage.Reward.GoldMax (config values in gold pieces).
 *
 *   2. Paragon Glyph
 *      One item drawn uniformly at random from the g_Glyphs pool.
 *      All six glyphs have no class restriction on item_template, so
 *      the selection is genuinely random.
 *
 *   3. Paragon Points or a full Paragon Level
 *      Rolled as a single binary outcome:
 *        GuildVillage.Reward.FullLevelChancePct  (default 10%) → full level
 *        Remaining %                             (default 90%) → board points
 *      Delegated to OtR_GrantParagonProgress() (mod_synival_paragon.cpp)
 *      so it shares the translation unit with all static paragon helpers and
 *      avoids linker visibility issues.
 *
 * Eligibility:
 *   Player must be online and inside their guild's own village phase when the
 *   tick fires. Offline players are not compensated retroactively.
 *   Last-reward time is persisted per character in character_gv_reward_tracker.
 *
 * Architecture:
 *   GuildVillageRewardWorldScript — WorldScript::OnUpdate accumulates diff
 *   until IntervalSeconds elapses, then iterates all sessions.
 */

#include "mod_paragon_board.h"     // g_Glyphs, g_ParagonMutex, OtR_GrantParagonProgress
#include "ScriptMgr.h"
#include "Player.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "World.h"
#include "Guild.h"
#include "GuildMgr.h"
#include "Maps/MapMgr.h"
#include "Random.h"

#include <mutex>
#include <vector>
#include <ctime>

// ─────────────────────────────────────────────────────────────────────────────
// Configuration helpers
// ─────────────────────────────────────────────────────────────────────────────

namespace GVReward
{
    static inline uint32 IntervalSeconds()
    {
        return sConfigMgr->GetOption<uint32>("GuildVillage.Reward.IntervalSeconds", 10800);
    }
    static inline uint32 GoldMin()
    {
        return sConfigMgr->GetOption<uint32>("GuildVillage.Reward.GoldMin", 1);
    }
    static inline uint32 GoldMax()
    {
        return sConfigMgr->GetOption<uint32>("GuildVillage.Reward.GoldMax", 2000);
    }
    static inline uint32 BoardPoints()
    {
        return sConfigMgr->GetOption<uint32>("GuildVillage.Reward.BoardPoints", 3);
    }
    static inline uint32 FullLevelChancePct()
    {
        return sConfigMgr->GetOption<uint32>("GuildVillage.Reward.FullLevelChancePct", 10);
    }
    static inline uint32 VillageMap()
    {
        return sConfigMgr->GetOption<uint32>("GuildVillage.Default.Map", 37);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase check
// Each guild's village phase = guildId + 10 (mirrors guild_village_create.cpp)
// ─────────────────────────────────────────────────────────────────────────────

static bool IsPlayerInOwnVillage(Player* player)
{
    if (!player || !player->IsInWorld())
        return false;

    if (player->GetMapId() != GVReward::VillageMap())
        return false;

    uint32 guildId = player->GetGuildId();
    if (!guildId)
        return false;

    uint32 expectedPhase = guildId + 10;
    return (player->GetPhaseMask() & (1u << (expectedPhase - 1))) != 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Reward distribution
// ─────────────────────────────────────────────────────────────────────────────

static void DistributeRewardToPlayer(Player* player)
{
    if (!player || !player->IsInWorld())
        return;

    ObjectGuid guid = player->GetGUID();

    // ── 1. Gold ──────────────────────────────────────────────────────────────
    uint32 goldMin = GVReward::GoldMin();
    uint32 goldMax = GVReward::GoldMax();
    if (goldMin > goldMax)
        std::swap(goldMin, goldMax);

    uint32 goldGold   = goldMin + urand(0, goldMax - goldMin);   // in gold pieces
    int32  copperAmount = static_cast<int32>(goldGold * 10000u); // gold → copper

    player->ModifyMoney(copperAmount);

    // ── 2. Paragon Glyph ─────────────────────────────────────────────────────
    // Lock g_ParagonMutex only to read the glyph pool, then release before
    // calling StoreNewItem (which can trigger hooks with their own locks).
    {
        uint32 chosenEntry = 0;

        {
            std::lock_guard<std::mutex> lock(g_ParagonMutex);
            if (!g_Glyphs.empty())
            {
                std::vector<uint32> entries;
                entries.reserve(g_Glyphs.size());
                for (auto const& [id, glyph] : g_Glyphs)
                    if (glyph.itemEntry != 0)
                        entries.push_back(glyph.itemEntry);

                if (!entries.empty())
                    chosenEntry = entries[urand(0u, static_cast<uint32>(entries.size()) - 1u)];
            }
        } // lock released before any item operations

        if (chosenEntry != 0)
        {
            ItemPosCountVec dest;
            if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, chosenEntry, 1) == EQUIP_ERR_OK)
            {
                Item* glyphItem = player->StoreNewItem(dest, chosenEntry, true);
                if (glyphItem)
                    player->SendNewItem(glyphItem, 1, true, false);
            }
        }
    }

    // ── 3. Paragon Progress ───────────────────────────────────────────────────
    // OtR_GrantParagonProgress is defined in mod_synival_paragon.cpp and shares
    // its translation unit with all static paragon helpers. It acquires
    // g_ParagonMutex internally, so we must NOT hold it here.
    bool fullLevel = roll_chance_i(static_cast<int32>(GVReward::FullLevelChancePct()));
    OtR_GrantParagonProgress(player, fullLevel, GVReward::BoardPoints());

    // ── Notification ──────────────────────────────────────────────────────────
    std::string paragonMsg = fullLevel
        ? "a full Paragon Level"
        : std::to_string(GVReward::BoardPoints()) + " Board Points";

    player->SendSystemMessage(Acore::StringFormat(
        "|cffFFD700[Village Reward]|r Your guild rewards you for your dedication. "
        "|cffFFD700{}g|r in gold, a glyph added to your bags, and {} granted.",
        goldGold, paragonMsg));

    // ── Persist timestamp ─────────────────────────────────────────────────────
    uint32 now = static_cast<uint32>(std::time(nullptr));
    CharacterDatabase.Execute(
        "INSERT INTO character_gv_reward_tracker (guid, last_reward_time) "
        "VALUES ({}, {}) ON DUPLICATE KEY UPDATE last_reward_time = {}",
        guid.GetCounter(), now, now);
}

// ─────────────────────────────────────────────────────────────────────────────
// World Script — tick loop
// ─────────────────────────────────────────────────────────────────────────────

class GuildVillageRewardWorldScript : public WorldScript
{
public:
    GuildVillageRewardWorldScript() : WorldScript("GuildVillageRewardWorldScript") { }

private:
    uint32 _elapsed = 0;

    void OnUpdate(uint32 diff) override
    {
        _elapsed += diff;

        uint32 intervalMs = GVReward::IntervalSeconds() * 1000u;
        if (_elapsed < intervalMs)
            return;

        _elapsed = 0;

        uint32 rewarded = 0;

        SessionMap const& sessions = sWorld->GetAllSessions();
        for (auto const& [accountId, session] : sessions)
        {
            if (!session)
                continue;

            Player* player = session->GetPlayer();
            if (!player || !player->IsInWorld() || !player->IsAlive())
                continue;

            if (!IsPlayerInOwnVillage(player))
                continue;

            DistributeRewardToPlayer(player);
            ++rewarded;
        }

        if (rewarded > 0)
            LOG_INFO("module", "OtR: Village periodic rewards distributed to {} player(s).", rewarded);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Registration
// ─────────────────────────────────────────────────────────────────────────────

void RegisterGuildVillagePeriodicReward()
{
    new GuildVillageRewardWorldScript();
}
