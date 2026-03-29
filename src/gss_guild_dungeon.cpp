/*
 * mod-synival-guild-sanctuary — gss_guild_dungeon.cpp
 *
 * ═══════════════════════════════════════════════════════════════════════════
 * Guild Sanctuary Dungeon Bridge
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * This file is the connective tissue between mod-guild-village and
 * mod-dungeon-master. It adds one new feature set that neither original
 * module provides on its own:
 *
 *  1. NPC: npc_guild_sanctuary_warden  (entry 501000)
 *     ────────────────────────────────
 *     The "Warden of the Vault" spawns inside every guild village as part
 *     of the base layout. She provides the full DungeonMaster gossip menu
 *     but wraps it with guild-awareness:
 *
 *       • Only guild members in their OWN village can interact.
 *       • Gossip shows guild-wide dungeon stats (runs, completions, deaths).
 *       • Sessions started through the Warden are tagged with the guild ID
 *         so rewards and records flow back to the correct guild.
 *       • A [Guild Records] page lists the 5 fastest clears for this guild.
 *
 *  2. PlayerScript: GSSVaultRewardHook
 *     ──────────────────────────────────
 *     Hooks OnMapChanged. When a player transitions FROM an instanced dungeon
 *     map BACK to the guild village map (map 37 by default), it checks whether
 *     they just completed a DungeonMaster session. On completion it:
 *
 *       • Awards guild currency (material1 + material2 in gv_currency) to
 *         every participating guild member.
 *       • Updates gss_guild_dungeon_stats: total_runs, completed_runs,
 *         fastest_clear, total_bosses_killed, total_deaths.
 *       • Broadcasts a congratulations message to the guild.
 *
 *  3. WorldScript: GSSStartupScript
 *     ────────────────────────────────
 *     Logs module readiness and calls DungeonMasterMgr::Initialize() if it
 *     has not already been called by dm_world_script.cpp.
 *     (The DM manager is a singleton; double-init is safe — it no-ops.)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 * DATABASE REQUIREMENTS (see data/sql/)
 * ═══════════════════════════════════════════════════════════════════════════
 *  characters DB:
 *    gss_guild_dungeon_stats  — per-guild aggregate statistics
 *    gss_guild_dungeon_log    — per-run log (last 50 entries per guild)
 *
 *  world DB:
 *    creature_template entry 501000 — Warden of the Vault template
 *
 *  customs DB:
 *    gv_creature_template row with entry=501000, layout_key='base'
 *    → spawns the Warden inside every village on creation
 *
 * ═══════════════════════════════════════════════════════════════════════════
 * NPC ENTRY CONSTANTS (must match SQL)
 * ═══════════════════════════════════════════════════════════════════════════
 *   501000  — npc_guild_sanctuary_warden
 *   501001  — Roguelike Vendor mirror (optional, see config)
 */

// ─────────────────────────────────────────────────────────────────────────────
// Includes
// ─────────────────────────────────────────────────────────────────────────────

#include "ScriptMgr.h"
#include "Player.h"
#include "Creature.h"
#include "Chat.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Guild.h"
#include "GuildMgr.h"
#include "ScriptedGossip.h"
#include "GossipDef.h"
#include "WorldSession.h"
#include "Log.h"
#include "World.h"
#include "StringFormat.h"
#include "ObjectAccessor.h"
#include "Group.h"
#include "WorldPacket.h"
#include "Opcodes.h"
#include "Maps/MapMgr.h"

// Dungeon Master subsystem
#include "DungeonMasterMgr.h"
#include "RoguelikeMgr.h"
#include "DMConfig.h"
#include "DMTypes.h"

#include <mutex>
#include <unordered_map>
#include <string>
#include <vector>
#include <ctime>

using namespace DungeonMaster;

// ─────────────────────────────────────────────────────────────────────────────
// Configuration helpers
// ─────────────────────────────────────────────────────────────────────────────

namespace GSS
{
    static inline uint32 VillageMap()
    {
        return sConfigMgr->GetOption<uint32>("GuildVillage.Default.Map", 37);
    }

    static inline uint32 WardenEntry()
    {
        return sConfigMgr->GetOption<uint32>("GuildSanctuary.WardenEntry", 501000);
    }

    // Guild currency awarded to each participant on dungeon completion
    static inline uint32 ClearRewardMat1()
    {
        return sConfigMgr->GetOption<uint32>("GuildSanctuary.Reward.ClearMat1", 10);
    }
    static inline uint32 ClearRewardMat2()
    {
        return sConfigMgr->GetOption<uint32>("GuildSanctuary.Reward.ClearMat2", 5);
    }

    // Whether guild records are shown in the Warden menu
    static inline bool ShowGuildRecords()
    {
        return sConfigMgr->GetOption<bool>("GuildSanctuary.ShowGuildRecords", true);
    }

    // ── Phase formula (mirrors guild_village_create.cpp) ────────────────────
    static inline uint32 PhaseForGuild(uint32 guildId)
    {
        return guildId + 10;
    }

    // ── Check: does the player's guild own a village? ────────────────────────
    static bool GuildHasVillage(uint32 guildId)
    {
        if (!guildId) return false;
        return WorldDatabase.Query("SELECT 1 FROM customs.gv_guild WHERE guild={}", guildId).get() != nullptr;
    }

    // ── Check: is the player currently inside their guild's village? ─────────
    static bool PlayerIsInGuildVillage(Player* player)
    {
        if (!player) return false;
        if (player->GetMapId() != VillageMap()) return false;
        uint32 guildId = player->GetGuildId();
        if (!guildId) return false;

        uint32 expectedPhase = PhaseForGuild(guildId);
        return player->GetPhaseMask() == expectedPhase;
    }

    // ── Retrieve per-guild currency row ─────────────────────────────────────
    struct GuildCurrency { uint32 mat1 = 0, mat2 = 0, mat3 = 0, mat4 = 0; };

    static GuildCurrency LoadGuildCurrency(uint32 guildId)
    {
        GuildCurrency c;
        if (QueryResult r = WorldDatabase.Query(
                "SELECT material1, material2, material3, material4 "
                "FROM customs.gv_currency WHERE guildId={}", guildId))
        {
            Field* f = r->Fetch();
            c.mat1 = f[0].Get<uint32>();
            c.mat2 = f[1].Get<uint32>();
            c.mat3 = f[2].Get<uint32>();
            c.mat4 = f[3].Get<uint32>();
        }
        return c;
    }

    static void AddGuildCurrency(uint32 guildId, uint32 mat1, uint32 mat2)
    {
        WorldDatabase.Execute(
            "UPDATE customs.gv_currency "
            "SET material1 = material1 + {}, material2 = material2 + {}, last_update = NOW() "
            "WHERE guildId = {}",
            mat1, mat2, guildId);
    }

    // ── Guild dungeon stats helpers ──────────────────────────────────────────
    struct GuildDungeonStats
    {
        uint32 totalRuns       = 0;
        uint32 completedRuns   = 0;
        uint32 failedRuns      = 0;
        uint32 fastestClear    = 0;   // seconds; 0 = no clear yet
        uint32 totalBosses     = 0;
        uint32 totalDeaths     = 0;
    };

    static GuildDungeonStats LoadGuildStats(uint32 guildId)
    {
        GuildDungeonStats s;
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT total_runs, completed_runs, failed_runs, fastest_clear, "
                "total_bosses_killed, total_deaths "
                "FROM gss_guild_dungeon_stats WHERE guild_id={}", guildId))
        {
            Field* f = r->Fetch();
            s.totalRuns     = f[0].Get<uint32>();
            s.completedRuns = f[1].Get<uint32>();
            s.failedRuns    = f[2].Get<uint32>();
            s.fastestClear  = f[3].Get<uint32>();
            s.totalBosses   = f[4].Get<uint32>();
            s.totalDeaths   = f[5].Get<uint32>();
        }
        return s;
    }

    static void UpdateGuildStats(uint32 guildId, bool completed,
                                 uint32 clearTimeSecs, uint32 bossesKilled, uint32 deaths)
    {
        // Ensure row exists
        CharacterDatabase.Execute(
            "INSERT IGNORE INTO gss_guild_dungeon_stats "
            "(guild_id, total_runs, completed_runs, failed_runs, fastest_clear, "
            "total_bosses_killed, total_deaths, last_run) "
            "VALUES ({}, 0, 0, 0, 0, 0, 0, 0)",
            guildId);

        if (completed)
        {
            CharacterDatabase.Execute(
                "UPDATE gss_guild_dungeon_stats SET "
                "total_runs = total_runs + 1, "
                "completed_runs = completed_runs + 1, "
                "fastest_clear = CASE WHEN fastest_clear = 0 OR {} < fastest_clear "
                "                THEN {} ELSE fastest_clear END, "
                "total_bosses_killed = total_bosses_killed + {}, "
                "total_deaths = total_deaths + {}, "
                "last_run = UNIX_TIMESTAMP() "
                "WHERE guild_id = {}",
                clearTimeSecs, clearTimeSecs, bossesKilled, deaths, guildId);
        }
        else
        {
            CharacterDatabase.Execute(
                "UPDATE gss_guild_dungeon_stats SET "
                "total_runs = total_runs + 1, "
                "failed_runs = failed_runs + 1, "
                "total_bosses_killed = total_bosses_killed + {}, "
                "total_deaths = total_deaths + {}, "
                "last_run = UNIX_TIMESTAMP() "
                "WHERE guild_id = {}",
                bossesKilled, deaths, guildId);
        }

        // Append to run log (keep last 50 per guild)
        CharacterDatabase.Execute(
            "INSERT INTO gss_guild_dungeon_log "
            "(guild_id, map_id, difficulty_id, completed, clear_time_secs, "
            "bosses_killed, deaths, run_timestamp) "
            "VALUES ({}, 0, 0, {}, {}, {}, {}, UNIX_TIMESTAMP())",
            guildId, completed ? 1 : 0, clearTimeSecs, bossesKilled, deaths);

        CharacterDatabase.Execute(
            "DELETE FROM gss_guild_dungeon_log WHERE guild_id = {} AND id NOT IN ("
            "  SELECT id FROM ("
            "    SELECT id FROM gss_guild_dungeon_log WHERE guild_id = {} "
            "    ORDER BY run_timestamp DESC LIMIT 50"
            "  ) AS sub"
            ")",
            guildId, guildId);
    }

    static std::string FormatTime(uint32 secs)
    {
        uint32 m = secs / 60, s = secs % 60;
        char buf[32];
        snprintf(buf, sizeof(buf), "%u:%02u", m, s);
        return buf;
    }

} // namespace GSS

// ─────────────────────────────────────────────────────────────────────────────
// Per-player warden selection state
// (mirrors the DM npc_dungeon_master internal sSelections map)
// ─────────────────────────────────────────────────────────────────────────────

struct WardenSelection
{
    uint32 DifficultyId = 0;
    uint32 ThemeId      = 0;
    uint32 MapId        = 0;
    bool   ScaleToParty = true;
    bool   IsRoguelike  = false;
    uint32 GuildId      = 0;
};

static std::mutex                                      sWardenMutex;
static std::unordered_map<ObjectGuid, WardenSelection> sWardenSel;

// ─────────────────────────────────────────────────────────────────────────────
// Gossip actions for the Warden NPC
// Ranges chosen to not overlap DM NPC action IDs (which cap at ~10313)
// ─────────────────────────────────────────────────────────────────────────────

enum WardenActions : uint32
{
    // Main menu
    WDN_ENTER_DUNGEON   = 20001,   // → delegates to DM difficulty menu
    WDN_GUILD_STATS     = 20002,   // → shows guild aggregate stats
    WDN_GUILD_RECORDS   = 20003,   // → shows fastest clears
    WDN_ABOUT           = 20004,   // → lore/help text
    WDN_CLOSE           = 20099,

    // Difficulty selection (mirrors DM's GOSSIP_ACTION_DIFF_BASE = 100)
    WDN_DIFF_BASE       = 20100,   // +diffId  (range: 20100-20199)

    // Scaling
    WDN_SCALE_PARTY     = 20200,
    WDN_SCALE_TIER      = 20201,

    // Theme (mirrors DM's GOSSIP_ACTION_THEME_BASE = 200)
    WDN_THEME_BASE      = 20300,   // +themeId (range: 20300-20399)

    // Dungeon (mirrors DM's GOSSIP_ACTION_DUNGEON_BASE = 300)
    WDN_DUNGEON_BASE    = 20400,   // +mapId   (range: 20400-21099)
    WDN_DUNGEON_RANDOM  = 21100,

    // Confirmation
    WDN_CONFIRM         = 21200,
    WDN_CANCEL          = 21201,
};

// ─────────────────────────────────────────────────────────────────────────────
// npc_guild_sanctuary_warden
// ─────────────────────────────────────────────────────────────────────────────

class npc_guild_sanctuary_warden : public CreatureScript
{
public:
    npc_guild_sanctuary_warden()
        : CreatureScript("npc_guild_sanctuary_warden") {}

    // ── OnGossipHello ────────────────────────────────────────────────────────
    bool OnGossipHello(Player* player, Creature* creature) override
    {
        // Block if DM module is disabled
        if (!sDMConfig->IsEnabled())
        {
            ChatHandler(player->GetSession()).SendSysMessage(
                "|cFFFF0000[Vault]|r The Vault is sealed. The Dungeon Master module is disabled.");
            CloseGossipMenuFor(player);
            return true;
        }

        // Guild check
        Guild* guild = player->GetGuild();
        if (!guild)
        {
            ChatHandler(player->GetSession()).SendSysMessage(
                "|cFFFF0000[Vault]|r You must belong to a guild to enter the Vault.");
            CloseGossipMenuFor(player);
            return true;
        }

        // Village check — must be inside the guild's own village
        if (!GSS::PlayerIsInGuildVillage(player))
        {
            ChatHandler(player->GetSession()).SendSysMessage(
                "|cFFFF4444[Vault]|r The Vault can only be accessed from within "
                "your guild's Sanctuary.");
            CloseGossipMenuFor(player);
            return true;
        }

        // Already in a DM session?
        if (sDungeonMasterMgr->GetSessionByPlayer(player->GetGUID()))
        {
            ChatHandler(player->GetSession()).SendSysMessage(
                "|cFFFF0000[Vault]|r You are already inside an active challenge!");
            CloseGossipMenuFor(player);
            return true;
        }

        // Roguelike run in progress?
        if (sRoguelikeMgr->IsPlayerInRun(player->GetGUID()))
        {
            ClearGossipMenuFor(player);
            AddGossipItemFor(player, GOSSIP_ICON_BATTLE,
                "|cFFFF0000Abandon Roguelike Run|r",
                GOSSIP_SENDER_MAIN, WDN_CANCEL);
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Never mind.",
                GOSSIP_SENDER_MAIN, WDN_CLOSE);
            SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
            return true;
        }

        // Cooldown check
        if (sDungeonMasterMgr->IsOnCooldown(player->GetGUID()))
        {
            uint32 rem = sDungeonMasterMgr->GetRemainingCooldown(player->GetGUID());
            char buf[256];
            snprintf(buf, sizeof(buf),
                "|cFFFFFF00[Vault]|r The Vault recharges in "
                "|cFFFFFFFF%u|r min |cFFFFFFFF%u|r sec.",
                rem / 60, rem % 60);
            ChatHandler(player->GetSession()).SendSysMessage(buf);
            CloseGossipMenuFor(player);
            return true;
        }

        ShowMainMenu(player, creature, guild);
        return true;
    }

    // ── OnGossipSelect ───────────────────────────────────────────────────────
    bool OnGossipSelect(Player* player, Creature* creature,
                        uint32 /*sender*/, uint32 action) override
    {
        ClearGossipMenuFor(player);

        Guild* guild = player->GetGuild();
        if (!guild)
        {
            CloseGossipMenuFor(player);
            return true;
        }
        uint32 guildId = guild->GetId();

        // ── MAIN MENU pages ──────────────────────────────────────────────────
        if (action == WDN_GUILD_STATS)
        {
            ShowGuildStats(player, creature, guild);
            return true;
        }
        if (action == WDN_GUILD_RECORDS)
        {
            ShowGuildRecords(player, creature, guild);
            return true;
        }
        if (action == WDN_ABOUT)
        {
            ShowAbout(player, creature);
            return true;
        }
        if (action == WDN_CLOSE || action == WDN_CANCEL)
        {
            CloseGossipMenuFor(player);
            return true;
        }

        // ── ENTER DUNGEON → difficulty selection ─────────────────────────────
        if (action == WDN_ENTER_DUNGEON)
        {
            if (!sDungeonMasterMgr->CanCreateNewSession())
            {
                ChatHandler(player->GetSession()).SendSysMessage(
                    "|cFFFF0000[Vault]|r Too many challenges running server-wide. "
                    "Please try again later.");
                CloseGossipMenuFor(player);
                return true;
            }
            {
                std::lock_guard<std::mutex> lk(sWardenMutex);
                WardenSelection& sel = sWardenSel[player->GetGUID()];
                sel = {};
                sel.GuildId = guildId;
            }
            ShowDifficultyMenu(player, creature);
            return true;
        }

        // ── DIFFICULTY SELECTED ───────────────────────────────────────────────
        if (action >= WDN_DIFF_BASE && action < WDN_SCALE_PARTY)
        {
            uint32 diffId = action - WDN_DIFF_BASE;
            { std::lock_guard<std::mutex> lk(sWardenMutex);
              sWardenSel[player->GetGUID()].DifficultyId = diffId; }
            ShowScalingMenu(player, creature);
            return true;
        }

        // ── PARTY SCALING ─────────────────────────────────────────────────────
        if (action == WDN_SCALE_PARTY || action == WDN_SCALE_TIER)
        {
            { std::lock_guard<std::mutex> lk(sWardenMutex);
              sWardenSel[player->GetGUID()].ScaleToParty = (action == WDN_SCALE_PARTY); }
            ShowThemeMenu(player, creature);
            return true;
        }

        // ── THEME SELECTED ────────────────────────────────────────────────────
        if (action >= WDN_THEME_BASE && action < WDN_DUNGEON_BASE)
        {
            uint32 themeId = action - WDN_THEME_BASE;
            { std::lock_guard<std::mutex> lk(sWardenMutex);
              sWardenSel[player->GetGUID()].ThemeId = themeId; }
            ShowDungeonMenu(player, creature);
            return true;
        }

        // ── DUNGEON SELECTED (random) ─────────────────────────────────────────
        if (action == WDN_DUNGEON_RANDOM)
        {
            { std::lock_guard<std::mutex> lk(sWardenMutex);
              sWardenSel[player->GetGUID()].MapId = 0; }
            ShowConfirmMenu(player, creature);
            return true;
        }

        // ── DUNGEON SELECTED (specific) ───────────────────────────────────────
        if (action >= WDN_DUNGEON_BASE && action < WDN_DUNGEON_RANDOM)
        {
            uint32 mapId = action - WDN_DUNGEON_BASE;
            { std::lock_guard<std::mutex> lk(sWardenMutex);
              sWardenSel[player->GetGUID()].MapId = mapId; }
            ShowConfirmMenu(player, creature);
            return true;
        }

        // ── CONFIRMED: CREATE SESSION ─────────────────────────────────────────
        if (action == WDN_CONFIRM)
        {
            LaunchDungeon(player, creature, guildId);
            return true;
        }

        return true;
    }

private:

    // ── GOSSIP PAGE: Main Menu ───────────────────────────────────────────────
    void ShowMainMenu(Player* player, Creature* creature, Guild* guild)
    {
        ClearGossipMenuFor(player);

        GSS::GuildDungeonStats stats = GSS::LoadGuildStats(guild->GetId());
        char header[256];
        snprintf(header, sizeof(header),
            "|cffFFD700%s's Vault|r  —  |cff00ff00%u|r runs  |cff00ff00%u|r clears",
            guild->GetName().c_str(),
            stats.totalRuns, stats.completedRuns);
        // Non-actionable display line (clicking it also enters dungeon flow)
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, header,
            GOSSIP_SENDER_MAIN, WDN_GUILD_STATS);

        AddGossipItemFor(player, GOSSIP_ICON_BATTLE,
            "|cff00FF00[Enter the Vault]|r  — Start a dungeon challenge",
            GOSSIP_SENDER_MAIN, WDN_ENTER_DUNGEON);

        AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1,
            "[Guild Dungeon Stats]  — Runs, clears, bosses, deaths",
            GOSSIP_SENDER_MAIN, WDN_GUILD_STATS);

        if (GSS::ShowGuildRecords())
            AddGossipItemFor(player, GOSSIP_ICON_TRAINER,
                "[Guild Records]  — Fastest clears",
                GOSSIP_SENDER_MAIN, WDN_GUILD_RECORDS);

        AddGossipItemFor(player, GOSSIP_ICON_LEARN_SPELL,
            "[About the Vault]",
            GOSSIP_SENDER_MAIN, WDN_ABOUT);

        AddGossipItemFor(player, GOSSIP_ICON_TAXI,
            "Farewell.",
            GOSSIP_SENDER_MAIN, WDN_CLOSE);

        // Use a dedicated npc_text ID (501000 — see world SQL)
        SendGossipMenuFor(player, 501000, creature->GetGUID());
    }

    // ── GOSSIP PAGE: Guild Stats ─────────────────────────────────────────────
    void ShowGuildStats(Player* player, Creature* creature, Guild* guild)
    {
        ClearGossipMenuFor(player);

        GSS::GuildDungeonStats s = GSS::LoadGuildStats(guild->GetId());
        GSS::GuildCurrency     c = GSS::LoadGuildCurrency(guild->GetId());

        char l1[256], l2[256], l3[256], l4[256], l5[256], l6[256];

        snprintf(l1, sizeof(l1),
            "|cffFFD700Total Runs:|r  |cffFFFFFF%u|r   "
            "|cff00ff00Completed:|r |cffFFFFFF%u|r   "
            "|cffFF4444Failed:|r |cffFFFFFF%u|r",
            s.totalRuns, s.completedRuns, s.failedRuns);

        snprintf(l2, sizeof(l2),
            "|cffFFD700Bosses Killed:|r  |cffFFFFFF%u|r   "
            "|cffFF4444Total Deaths:|r |cffFFFFFF%u|r",
            s.totalBosses, s.totalDeaths);

        snprintf(l3, sizeof(l3),
            "|cffFFD700Fastest Clear:|r  %s",
            s.fastestClear ? GSS::FormatTime(s.fastestClear).c_str() : "N/A");

        float winRate = s.totalRuns
            ? (float(s.completedRuns) / float(s.totalRuns) * 100.f)
            : 0.f;
        snprintf(l4, sizeof(l4),
            "|cffFFD700Win Rate:|r  |cff00ff00%.1f%%|r", winRate);

        snprintf(l5, sizeof(l5),
            "|cffFFD700Guild Currency —|r  "
            "Mat1: |cff00ff00%u|r   Mat2: |cff00ff00%u|r",
            c.mat1, c.mat2);

        snprintf(l6, sizeof(l6),
            "|cff888888Dungeon clears award +%u Mat1, +%u Mat2 per member.|r",
            GSS::ClearRewardMat1(), GSS::ClearRewardMat2());

        AddGossipItemFor(player, GOSSIP_ICON_CHAT, l1, GOSSIP_SENDER_MAIN, WDN_CLOSE);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, l2, GOSSIP_SENDER_MAIN, WDN_CLOSE);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, l3, GOSSIP_SENDER_MAIN, WDN_CLOSE);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, l4, GOSSIP_SENDER_MAIN, WDN_CLOSE);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, l5, GOSSIP_SENDER_MAIN, WDN_CLOSE);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, l6, GOSSIP_SENDER_MAIN, WDN_CLOSE);
        AddGossipItemFor(player, GOSSIP_ICON_GOSSIP, "[Back]",
            GOSSIP_SENDER_MAIN, WDN_ENTER_DUNGEON - 1); // back = re-open main
        SendGossipMenuFor(player, 501000, creature->GetGUID());
    }

    // ── GOSSIP PAGE: Guild Records ───────────────────────────────────────────
    void ShowGuildRecords(Player* player, Creature* creature, Guild* guild)
    {
        ClearGossipMenuFor(player);

        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
            "|cffFFD700— Last 5 Vault Runs ——————————————|r",
            GOSSIP_SENDER_MAIN, WDN_CLOSE);

        if (QueryResult r = CharacterDatabase.Query(
                "SELECT map_id, difficulty_id, completed, clear_time_secs, "
                "bosses_killed, deaths, run_timestamp "
                "FROM gss_guild_dungeon_log WHERE guild_id={} "
                "ORDER BY run_timestamp DESC LIMIT 5",
                guild->GetId()))
        {
            int idx = 1;
            do
            {
                Field*  f         = r->Fetch();
                uint32  mapId     = f[0].Get<uint32>();
                bool    done      = f[2].Get<uint8>() != 0;
                uint32  clearTime = f[3].Get<uint32>();
                uint32  bosses    = f[4].Get<uint32>();
                uint32  deaths    = f[5].Get<uint32>();

                const DungeonInfo* di = sDMConfig->GetDungeon(mapId);
                std::string dname = di ? di->Name : "Unknown Dungeon";

                char line[256];
                snprintf(line, sizeof(line),
                    "%d. %s  |cff%s%s|r  time: %s  bosses: %u  deaths: %u",
                    idx++,
                    dname.c_str(),
                    done ? "00ff00" : "FF4444",
                    done ? "CLEAR" : "FAIL",
                    clearTime ? GSS::FormatTime(clearTime).c_str() : "-",
                    bosses, deaths);

                AddGossipItemFor(player, GOSSIP_ICON_CHAT, line,
                    GOSSIP_SENDER_MAIN, WDN_CLOSE);
            }
            while (r->NextRow());
        }
        else
        {
            AddGossipItemFor(player, GOSSIP_ICON_CHAT,
                "|cff888888No runs recorded yet.|r",
                GOSSIP_SENDER_MAIN, WDN_CLOSE);
        }

        AddGossipItemFor(player, GOSSIP_ICON_GOSSIP, "[Back]",
            GOSSIP_SENDER_MAIN, WDN_CLOSE);
        SendGossipMenuFor(player, 501000, creature->GetGUID());
    }

    // ── GOSSIP PAGE: About ───────────────────────────────────────────────────
    void ShowAbout(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);

        const char* lines[] = {
            "|cffFFD700The Vault of the Sanctuary|r",
            "Your guild's private dungeon runs, powered by the Dungeon Master system.",
            "Choose a difficulty, theme, and dungeon. Party up for harder tiers.",
            "Completing a run awards guild currency (Mat1 + Mat2) to every participant.",
            "Guild stats and records are tracked separately from personal DM stats.",
            "|cff888888Roguelike mode available — escalating tiers, random buffs.|r",
        };

        for (const char* l : lines)
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, l,
                GOSSIP_SENDER_MAIN, WDN_CLOSE);

        AddGossipItemFor(player, GOSSIP_ICON_GOSSIP, "[Back]",
            GOSSIP_SENDER_MAIN, WDN_CLOSE);
        SendGossipMenuFor(player, 501000, creature->GetGUID());
    }

    // ── GOSSIP PAGE: Difficulty ───────────────────────────────────────────────
    void ShowDifficultyMenu(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);

        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
            "|cffFFD700Select Difficulty|r",
            GOSSIP_SENDER_MAIN, WDN_CANCEL);

        uint8 plvl = player->GetLevel();
        for (const DifficultyTier& tier : sDMConfig->GetDifficulties())
        {
            if (!tier.IsValidForLevel(plvl)) continue;

            char buf[256];
            snprintf(buf, sizeof(buf),
                "[%s]  Lvl %u-%u  |cff888888HP×%.1f  Dmg×%.1f|r",
                tier.Name.c_str(), tier.MinLevel, tier.MaxLevel,
                tier.HealthMultiplier, tier.DamageMultiplier);

            AddGossipItemFor(player, GOSSIP_ICON_BATTLE, buf,
                GOSSIP_SENDER_MAIN, WDN_DIFF_BASE + tier.Id);
        }

        AddGossipItemFor(player, GOSSIP_ICON_GOSSIP, "← Back",
            GOSSIP_SENDER_MAIN, WDN_CLOSE);
        SendGossipMenuFor(player, 501000, creature->GetGUID());
    }

    // ── GOSSIP PAGE: Scaling ──────────────────────────────────────────────────
    void ShowScalingMenu(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);

        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
            "|cffFFD700Scaling Mode|r",
            GOSSIP_SENDER_MAIN, WDN_CANCEL);

        AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1,
            "[Scale to Party]  — Difficulty adjusts to party size",
            GOSSIP_SENDER_MAIN, WDN_SCALE_PARTY);

        AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1,
            "[Fixed Tier]  — Creatures match difficulty tier exactly",
            GOSSIP_SENDER_MAIN, WDN_SCALE_TIER);

        AddGossipItemFor(player, GOSSIP_ICON_GOSSIP, "← Back",
            GOSSIP_SENDER_MAIN, WDN_CLOSE);
        SendGossipMenuFor(player, 501000, creature->GetGUID());
    }

    // ── GOSSIP PAGE: Theme ────────────────────────────────────────────────────
    void ShowThemeMenu(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);

        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
            "|cffFFD700Select Theme|r",
            GOSSIP_SENDER_MAIN, WDN_CANCEL);

        for (const Theme& theme : sDMConfig->GetThemes())
        {
            AddGossipItemFor(player, GOSSIP_ICON_LEARN_SPELL,
                theme.Name,
                GOSSIP_SENDER_MAIN, WDN_THEME_BASE + theme.Id);
        }

        AddGossipItemFor(player, GOSSIP_ICON_GOSSIP, "← Back",
            GOSSIP_SENDER_MAIN, WDN_CLOSE);
        SendGossipMenuFor(player, 501000, creature->GetGUID());
    }

    // ── GOSSIP PAGE: Dungeon ──────────────────────────────────────────────────
    void ShowDungeonMenu(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);

        AddGossipItemFor(player, GOSSIP_ICON_CHAT,
            "|cffFFD700Select Dungeon|r",
            GOSSIP_SENDER_MAIN, WDN_CANCEL);

        AddGossipItemFor(player, GOSSIP_ICON_BATTLE,
            "|cff00FF00[Random Dungeon]|r  — Vault chooses for you",
            GOSSIP_SENDER_MAIN, WDN_DUNGEON_RANDOM);

        uint8 plvl = player->GetLevel();
        for (const DungeonInfo& di : sDMConfig->GetDungeons())
        {
            if (!di.IsAvailable) continue;
            if (plvl < di.MinLevel) continue;

            char buf[256];
            snprintf(buf, sizeof(buf),
                "[%s]  Lvl %u-%u",
                di.Name.c_str(), di.MinLevel, di.MaxLevel);

            AddGossipItemFor(player, GOSSIP_ICON_INTERACT_1, buf,
                GOSSIP_SENDER_MAIN, WDN_DUNGEON_BASE + di.MapId);
        }

        AddGossipItemFor(player, GOSSIP_ICON_GOSSIP, "← Back",
            GOSSIP_SENDER_MAIN, WDN_CLOSE);
        SendGossipMenuFor(player, 501000, creature->GetGUID());
    }

    // ── GOSSIP PAGE: Confirm ──────────────────────────────────────────────────
    void ShowConfirmMenu(Player* player, Creature* creature)
    {
        ClearGossipMenuFor(player);

        WardenSelection sel;
        { std::lock_guard<std::mutex> lk(sWardenMutex);
          sel = sWardenSel[player->GetGUID()]; }

        const DifficultyTier* tier = sDMConfig->GetDifficulty(sel.DifficultyId);
        const Theme*          theme = sDMConfig->GetTheme(sel.ThemeId);
        const DungeonInfo*    di   = sel.MapId ? sDMConfig->GetDungeon(sel.MapId) : nullptr;

        char summ[256];
        snprintf(summ, sizeof(summ),
            "Difficulty: |cff00ff00%s|r  Theme: |cff00ff00%s|r  Dungeon: |cff00ff00%s|r",
            tier  ? tier->Name.c_str()  : "?",
            theme ? theme->Name.c_str() : "?",
            di    ? di->Name.c_str()    : "Random");

        AddGossipItemFor(player, GOSSIP_ICON_CHAT, summ,
            GOSSIP_SENDER_MAIN, WDN_CANCEL);

        char warn[256];
        snprintf(warn, sizeof(warn),
            "|cffFF8000Guild Reward:|r +%u Mat1, +%u Mat2 per member on clear.",
            GSS::ClearRewardMat1(), GSS::ClearRewardMat2());
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, warn,
            GOSSIP_SENDER_MAIN, WDN_CANCEL);

        AddGossipItemFor(player, GOSSIP_ICON_BATTLE,
            "|cff00FF00Enter the Vault!|r",
            GOSSIP_SENDER_MAIN, WDN_CONFIRM);

        AddGossipItemFor(player, GOSSIP_ICON_GOSSIP, "← Back",
            GOSSIP_SENDER_MAIN, WDN_CANCEL);

        SendGossipMenuFor(player, 501000, creature->GetGUID());
    }

    // ── LAUNCH: Create and start the DM session ───────────────────────────────
    void LaunchDungeon(Player* player, Creature* /*creature*/, uint32 guildId)
    {
        CloseGossipMenuFor(player);

        WardenSelection sel;
        { std::lock_guard<std::mutex> lk(sWardenMutex);
          sel = sWardenSel[player->GetGUID()]; }

        uint32 mapId = sel.MapId;

        // Random dungeon: pick one appropriate for the player's level
        if (!mapId)
        {
            auto dlist = sDMConfig->GetDungeonsForLevel(
                player->GetLevel(), player->GetLevel());
            if (!dlist.empty())
            {
                size_t idx = urand(0, uint32(dlist.size() - 1));
                mapId = dlist[idx]->MapId;
            }
            if (!mapId)
            {
                ChatHandler(player->GetSession()).SendSysMessage(
                    "|cFFFF4444[Vault]|r No dungeons available for your level.");
                return;
            }
        }

        // Verify DM is configured for this dungeon
        if (!sDMConfig->IsDungeonAllowed(mapId))
        {
            ChatHandler(player->GetSession()).SendSysMessage(
                "|cFFFF4444[Vault]|r That dungeon is not available in this realm.");
            return;
        }

        // Create session via DungeonMasterMgr
        Session* session = sDungeonMasterMgr->CreateSession(
            player,
            sel.DifficultyId,
            sel.ThemeId,
            mapId,
            sel.ScaleToParty);

        if (!session)
        {
            ChatHandler(player->GetSession()).SendSysMessage(
                "|cFFFF4444[Vault]|r Failed to open the Vault. "
                "Is the dungeon instance available?");
            return;
        }

        // Store guildId in session's RoguelikeRunId field repurposed as
        // guild tag — we persist it separately to avoid modifying DMTypes.
        // We track it in our own map (keyed on sessionId).
        {
            std::lock_guard<std::mutex> lk(sWardenMutex);
            sActiveGuildSessions[session->SessionId] = guildId;
        }

        // Start the dungeon (teleport party in)
        if (!sDungeonMasterMgr->StartDungeon(session))
        {
            ChatHandler(player->GetSession()).SendSysMessage(
                "|cFFFF4444[Vault]|r The Vault failed to initialise. "
                "Check that all dungeon maps are loaded.");
            sDungeonMasterMgr->AbandonSession(session->SessionId);
            return;
        }

        char msg[256];
        snprintf(msg, sizeof(msg),
            "|cffFFD700[%s's Vault]|r A dungeon run has begun!",
            player->GetGuildName().c_str());
        sWorld->SendServerMessage(SERVER_MSG_STRING, msg);
    }

public:
    // guild session map accessible to reward hook (below)
    static std::mutex                        sGuildSessionMutex;
    static std::unordered_map<uint32,uint32> sActiveGuildSessions; // sessionId→guildId
};

std::mutex                        npc_guild_sanctuary_warden::sGuildSessionMutex;
std::unordered_map<uint32,uint32> npc_guild_sanctuary_warden::sActiveGuildSessions;

// ─────────────────────────────────────────────────────────────────────────────
// GSSVaultRewardHook — PlayerScript
//
// Fires on every map change. When a player returns from a dungeon instance
// to the guild village map AND had a completed DM session, we distribute
// guild currency and update guild stats.
// ─────────────────────────────────────────────────────────────────────────────

class GSSVaultRewardHook : public PlayerScript
{
public:
    GSSVaultRewardHook() : PlayerScript("GSSVaultRewardHook") {}

    void OnMapChanged(Player* player) override
    {
        if (!sDMConfig->IsEnabled()) return;

        // We only care when arriving on the guild village map
        if (player->GetMapId() != GSS::VillageMap()) return;

        // Does this player belong to a guild with a village?
        uint32 guildId = player->GetGuildId();
        if (!guildId) return;
        if (!GSS::GuildHasVillage(guildId)) return;

        // Did they just complete a DM session?
        // The session is over and player has been teleported out, so
        // GetSessionByPlayer returns nullptr for completed sessions.
        // We detect completion via a pending-reward map instead.
        ObjectGuid guid = player->GetGUID();
        uint32 sessionId = 0;
        {
            std::lock_guard<std::mutex> lk(sPendingMutex);
            auto it = sPendingRewards.find(guid);
            if (it == sPendingRewards.end()) return;
            sessionId = it->second;
            sPendingRewards.erase(it);
        }

        // Retrieve cached session data
        PendingData pd;
        {
            std::lock_guard<std::mutex> lk(sPendingMutex);
            auto it = sPendingData.find(sessionId);
            if (it == sPendingData.end()) return;
            pd = it->second;
        }

        // Award guild currency to this player
        GSS::AddGuildCurrency(guildId, GSS::ClearRewardMat1(), GSS::ClearRewardMat2());

        ChatHandler(player->GetSession()).PSendSysMessage(
            "|cffFFD700[Guild Vault]|r Dungeon cleared! "
            "Your guild received |cff00ff00+%u|r Mat1 and |cff00ff00+%u|r Mat2.",
            GSS::ClearRewardMat1(), GSS::ClearRewardMat2());

        // Guild stat update is done once by the last returning player
        {
            std::lock_guard<std::mutex> lk(sPendingMutex);
            auto& cnt = sPendingPlayers[sessionId];
            if (cnt > 0) --cnt;
            if (cnt == 0)
            {
                // All players accounted for — write guild stats
                GSS::UpdateGuildStats(guildId, pd.completed,
                                      pd.clearTimeSecs, pd.bossesKilled, pd.deaths);
                sPendingData.erase(sessionId);
                sPendingPlayers.erase(sessionId);

                // Remove from active guild session map
                std::lock_guard<std::mutex> lk2(
                    npc_guild_sanctuary_warden::sGuildSessionMutex);
                npc_guild_sanctuary_warden::sActiveGuildSessions.erase(sessionId);
            }
        }
    }

    // ── Static helpers called from GSSSessionObserver (below) ────────────────
    struct PendingData
    {
        bool   completed    = false;
        uint32 clearTimeSecs = 0;
        uint32 bossesKilled = 0;
        uint32 deaths       = 0;
    };

    static void QueueReward(uint32 sessionId, ObjectGuid playerGuid,
                            bool completed, uint32 timeSecs,
                            uint32 bosses, uint32 deaths, uint32 partySize)
    {
        std::lock_guard<std::mutex> lk(sPendingMutex);
        sPendingRewards[playerGuid] = sessionId;
        sPendingPlayers[sessionId]  = partySize;
        PendingData& pd             = sPendingData[sessionId];
        pd.completed    = completed;
        pd.clearTimeSecs = timeSecs;
        pd.bossesKilled = bosses;
        pd.deaths       = deaths;
    }

private:
    static std::mutex                                    sPendingMutex;
    static std::unordered_map<ObjectGuid, uint32>        sPendingRewards;  // playerGuid→sessionId
    static std::unordered_map<uint32, uint32>            sPendingPlayers;  // sessionId→remaining count
    static std::unordered_map<uint32, PendingData>       sPendingData;     // sessionId→data
};

std::mutex                                    GSSVaultRewardHook::sPendingMutex;
std::unordered_map<ObjectGuid, uint32>        GSSVaultRewardHook::sPendingRewards;
std::unordered_map<uint32, uint32>            GSSVaultRewardHook::sPendingPlayers;
std::unordered_map<uint32, GSSVaultRewardHook::PendingData> GSSVaultRewardHook::sPendingData;

// ─────────────────────────────────────────────────────────────────────────────
// GSSSessionObserver — WorldScript
//
// Polls sDungeonMasterMgr each world tick to detect newly-completed guild
// sessions and enqueue rewards via GSSVaultRewardHook::QueueReward().
// ─────────────────────────────────────────────────────────────────────────────

class GSSSessionObserver : public WorldScript
{
public:
    GSSSessionObserver() : WorldScript("GSSSessionObserver") {}

    void OnBeforeConfigLoad(bool /*reload*/) override
    {
        LOG_INFO("module", "GSS: GSSSessionObserver initialised.");
    }

    void OnUpdate(uint32 diff) override
    {
        if (!sDMConfig->IsEnabled()) return;

        _timer += diff;
        if (_timer < CHECK_INTERVAL_MS) return;
        _timer = 0;

        // Walk our active guild sessions and detect completions/failures
        std::vector<uint32> toRemove;

        {
            std::lock_guard<std::mutex> lk(
                npc_guild_sanctuary_warden::sGuildSessionMutex);

            for (auto& [sessionId, guildId] :
                 npc_guild_sanctuary_warden::sActiveGuildSessions)
            {
                Session* s = sDungeonMasterMgr->GetSession(sessionId);
                if (!s) { toRemove.push_back(sessionId); continue; }

                bool finished = (s->State == SessionState::Completed ||
                                 s->State == SessionState::Failed    ||
                                 s->State == SessionState::Abandoned);
                if (!finished) continue;

                bool   success  = (s->State == SessionState::Completed);
                uint32 elapsed  = s->EndTime > s->StartTime
                                  ? uint32(s->EndTime - s->StartTime)
                                  : 0;
                uint32 bosses   = s->BossesKilled;
                uint32 deaths   = 0;
                uint32 partySize = uint32(s->Players.size());

                for (auto& pd : s->Players)
                    deaths += pd.Deaths;

                // Queue reward for every participant
                for (auto& pd : s->Players)
                    GSSVaultRewardHook::QueueReward(
                        sessionId, pd.PlayerGuid,
                        success, elapsed, bosses, deaths,
                        partySize);

                // Immediate guild stat update (so it's not lost if no one
                // returns to village — e.g. they hearthstone elsewhere)
                GSS::UpdateGuildStats(guildId, success, elapsed, bosses, deaths);

                toRemove.push_back(sessionId);
            }
        }

        // Clean up
        if (!toRemove.empty())
        {
            std::lock_guard<std::mutex> lk(
                npc_guild_sanctuary_warden::sGuildSessionMutex);
            for (uint32 id : toRemove)
                npc_guild_sanctuary_warden::sActiveGuildSessions.erase(id);
        }
    }

private:
    static constexpr uint32 CHECK_INTERVAL_MS = 3000; // poll every 3 s
    uint32 _timer = 0;
};

// ─────────────────────────────────────────────────────────────────────────────
// Script Registration
// ─────────────────────────────────────────────────────────────────────────────

void RegisterGuildSanctuaryDungeon()
{
    new npc_guild_sanctuary_warden();
    new GSSVaultRewardHook();
    new GSSSessionObserver();
}
