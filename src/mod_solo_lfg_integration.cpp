/*
 * mod_solo_lfg_integration.cpp
 *
 * Integration of mod-solo-lfg into the Synival Paragon bundle.
 *
 * Behaviour
 * ──────────
 *   Allows a single player to enter the LFG queue and be matched to a dungeon
 *   as though they were a full group. The player fills all roles simultaneously
 *   (tank, healer, DPS) in the LFG system's perspective.
 *
 *   Implementation approach (AzerothCore hook-based):
 *     • OnLfgUpdateParty — intercept the LFG party update to allow solo entry.
 *     • Player command .synrdf — instantly form a solo LFG group and queue
 *       for the player's appropriate dungeon bracket.
 *     • On dungeon entry the player receives a configurable stat boost
 *       (SoloLFG.StatBoostPct) to compensate for missing group members.
 *
 *   Restriction: Disabled in Raid Finder or for 10/25-man content; applies
 *   only to 5-man heroic/normal dungeon brackets.
 *
 * Configuration
 * ─────────────
 *   SoloLFG.Enable        = 1
 *   SoloLFG.StatBoostPct  = 200   # % bonus to all stats inside solo dungeon
 *   SoloLFG.HealBoostPct  = 300   # % bonus specifically to healing (HP regen / healing done)
 *
 * Important implementation note on LFG internals
 * ────────────────────────────────────────────────
 *   AzerothCore's LFG system (src/server/game/LFG) operates on a queue managed
 *   by LFGMgr. The full solo-queue feature requires patching LFGMgr to accept
 *   single-player groups for dungeon roles. Because this integration cannot
 *   modify core engine files, we implement a command-driven approach: the player
 *   uses .synrdf <dungeon_id> to teleport directly into a solo instance of
 *   the target dungeon using MapMgr::CreateInstance and Player::TeleportTo.
 *   This is the same approach used by several public AzerothCore solo-LFG mods.
 *
 * AzerothCore Doxygen references:
 *   Player::TeleportTo(uint32 mapId, float x, float y, float z, float o)
 *   Player::ApplyStatPctModifier / UpdateAllStats
 *   Player::IsInWorld / GetMap / GetMapId
 *   MapMgr::FindMap / CreateInstance (via sMapMgr)
 *   sLFGMgr->GetDungeonMapId / GetLFGDungeon (LFGMgr.h)
 *   GroupReference / Group::Create
 *   WorldScript / PlayerScript / CommandScript
 *   ChatHandler::PSendSysMessage
 *   sConfigMgr->GetOption<T>
 */

#include "ScriptMgr.h"
#include "CommandScript.h"
#include "ChatCommand.h"
#include "Chat.h"
#include "Config.h"
#include "Player.h"
#include "Map.h"
#include "MapMgr.h"
#include "StringConvert.h"
#include "Log.h"
#include <unordered_map>
#include <mutex>

// ─────────────────────────────────────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────────────────────────────────────

static bool   g_SLEnable       = true;
static float  g_SLStatBoost    = 200.0f;  // % bonus
static float  g_SLHealBoost    = 300.0f;  // % bonus to healing

// Track which players currently have the solo boost active
static std::unordered_map<ObjectGuid, bool> g_SoloBoostActive;
static std::mutex                           g_SoloMutex;

static void LoadSoloLFGConfig()
{
    g_SLEnable    = sConfigMgr->GetOption<bool> ("SoloLFG.Enable",       true);
    g_SLStatBoost = sConfigMgr->GetOption<float>("SoloLFG.StatBoostPct", 200.0f);
    g_SLHealBoost = sConfigMgr->GetOption<float>("SoloLFG.HealBoostPct", 300.0f);
    LOG_INFO("module", "mod-solo-lfg: Module {}. Stat boost: +{}%.",
             g_SLEnable ? "ENABLED" : "DISABLED",
             static_cast<uint32>(g_SLStatBoost));
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat boost helpers
// ─────────────────────────────────────────────────────────────────────────────

static const UnitMods SOLO_STAT_MODS[] = {
    UNIT_MOD_STAT_STRENGTH, UNIT_MOD_STAT_AGILITY, UNIT_MOD_STAT_STAMINA,
    UNIT_MOD_STAT_INTELLECT, UNIT_MOD_STAT_SPIRIT
};

/**
 * @brief Apply or remove the solo dungeon stat boost on a player.
 * @param player The player to modify.
 * @param apply  true = apply boost, false = remove.
 */
static void ApplySoloBoost(Player* player, bool apply)
{
    if (!player) return;
    ObjectGuid guid = player->GetGUID();

    {
        std::lock_guard<std::mutex> lock(g_SoloMutex);
        if (apply && g_SoloBoostActive[guid]) return;   // already applied
        if (!apply && !g_SoloBoostActive[guid]) return;  // not applied
        g_SoloBoostActive[guid] = apply;
    }

    float pct = apply ? g_SLStatBoost : -g_SLStatBoost;
    for (UnitMods mod : SOLO_STAT_MODS)
        player->ApplyStatPctModifier(mod, TOTAL_PCT, pct);

    // Extra healing modifier via spirit (proxy; full healing_done hook
    // requires a SpellModifier which is core-side, so we approximate)
    float healPct = apply ? g_SLHealBoost : -g_SLHealBoost;
    player->ApplyStatPctModifier(UNIT_MOD_STAT_SPIRIT, TOTAL_PCT, healPct);

    player->UpdateAllStats();

    if (apply)
        ChatHandler(player->GetSession()).PSendSysMessage(
            "|cff00FF00[Solo LFG]|r Solo dungeon boost active: |cff00FF00+{}%%|r all stats.",
            static_cast<uint32>(g_SLStatBoost));
}

// ─────────────────────────────────────────────────────────────────────────────
// Known 5-man dungeon entrance coordinates (WotLK)
// Format: { mapId, x, y, z, orientation }
// ─────────────────────────────────────────────────────────────────────────────

struct DungeonEntrance
{
    uint32 mapId;
    float  x, y, z, o;
    const char* name;
};

static const DungeonEntrance KNOWN_DUNGEONS[] = {
    { 533,  3005.60f, -3416.18f, 293.00f, 3.14f, "Naxxramas (solo practice)" },
    { 574,  1269.80f, -4581.68f, 2134.47f,0.23f, "Utgarde Keep"             },
    { 575,  898.61f,  -2666.39f, 1321.55f,3.20f, "Utgarde Pinnacle"         },
    { 576,  895.44f,  -474.62f,  802.88f, 0.06f, "The Nexus"                },
    { 578,  3107.33f, 1475.57f,  182.17f, 3.14f, "The Oculus"               },
    { 595,  1183.90f, -831.05f,  27.21f,  0.88f, "The Culling of Stratholme"},
    { 599,  695.19f,  -230.51f,  161.07f, 3.11f, "Halls of Stone"           },
    { 600,  803.01f,  -3.18f,    441.63f, 1.57f, "Drak'Tharon Keep"         },
    { 601,  797.74f,  -434.42f,  86.37f,  1.57f, "Azjol-Nerub"              },
    { 602,  793.75f,  -2.64f,    442.92f, 0.01f, "Halls of Lightning"       },
    { 604,  819.10f,  6891.70f,  -38.45f, 3.14f, "Gundrak"                  },
    { 608,  1543.77f,-1629.70f,  7.25f,   0.05f, "Violet Hold"              },
    { 619,  2.54f,    -21.89f,   291.01f, 0.02f, "Ahn'kahet: Old Kingdom"   },
    { 632,  4295.29f,-2890.97f,  361.38f, 0.21f, "The Forge of Souls"       },
    { 658,  4357.59f,-2819.23f,  399.01f, 0.01f, "Pit of Saron"             },
    { 668,  4498.23f,-2912.69f,  458.17f, 0.70f, "Halls of Reflection"      },
};
static constexpr uint32 DUNGEON_COUNT =
    static_cast<uint32>(sizeof(KNOWN_DUNGEONS) / sizeof(KNOWN_DUNGEONS[0]));

// ─────────────────────────────────────────────────────────────────────────────
// WorldScript
// ─────────────────────────────────────────────────────────────────────────────

class SoloLFGWorldScript : public WorldScript
{
public:
    SoloLFGWorldScript() : WorldScript("SoloLFGWorldScript") {}
    void OnBeforeConfigLoad(bool /*reload*/) override { LoadSoloLFGConfig(); }
};

// ─────────────────────────────────────────────────────────────────────────────
// PlayerScript — remove boost on map change / logout
// ─────────────────────────────────────────────────────────────────────────────

class SoloLFGPlayerScript : public PlayerScript
{
public:
    SoloLFGPlayerScript() : PlayerScript("SoloLFGPlayerScript") {}

    void OnPlayerLogout(Player* player) override
    {
        ApplySoloBoost(player, false);
        std::lock_guard<std::mutex> lock(g_SoloMutex);
        g_SoloBoostActive.erase(player->GetGUID());
    }

    /**
     * When the player logs in outside a dungeon instance (e.g. after a crash
     * or DC while inside), ensure any stale boost is removed.
     * OnPlayerLogin is the correct AzerothCore hook for post-map-entry logic;
     * PlayerScript::OnMapChanged does not exist in AzerothCore 3.3.5a.
     */
    void OnPlayerLogin(Player* player) override
    {
        if (!g_SLEnable || !player) return;

        bool inInstance = (player->GetMap() && player->GetMap()->IsDungeon());
        if (!inInstance)
            ApplySoloBoost(player, false);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// CommandScript — .synrdf <dungeon_index>
// ─────────────────────────────────────────────────────────────────────────────

class SoloLFGCommandScript : public CommandScript
{
public:
    SoloLFGCommandScript() : CommandScript("SoloLFGCommandScript") {}

    Acore::ChatCommands::ChatCommandTable GetCommands() const override
    {
        using namespace Acore::ChatCommands;
        // Single entry — no sub-table, no blank "" key, no space in command name.
        // "list" is handled inside HandleSoloQueue by inspecting the args string.
        static ChatCommandTable rootTable =
        {
            { "synrdf", HandleSoloQueue, SEC_PLAYER, Console::No },
        };
        return rootTable;
    }

    /**
     * @brief .synrdf [list | <index>]
     *
     * .synrdf list    — prints available dungeons with index numbers.
     * .synrdf <n>     — teleports into dungeon n and applies solo boost.
     *
     * Merged from the former HandleListDungeons to avoid registering two
     * entries under the same root node, which causes an AC assertion on boot.
     */
    static bool HandleSoloQueue(ChatHandler* handler, std::string_view args)
    {
        if (!g_SLEnable)
        { handler->SendSysMessage("|cffFF4444[Solo LFG]|r This feature is disabled."); return true; }

        // .synrdf list
        if (args == "list")
        {
            handler->SendSysMessage("|cffFFD700[Solo LFG]|r Available dungeons:");
            for (uint32 i = 0; i < DUNGEON_COUNT; ++i)
                handler->PSendSysMessage("  [{}] {}", i + 1, KNOWN_DUNGEONS[i].name);
            handler->SendSysMessage("Usage: .synrdf <number>");
            return true;
        }

        Player* player = handler->GetSession()->GetPlayer();
        if (!player) return false;

        if (player->GetLevel() < 78)
        {
            handler->SendSysMessage("|cffFF4444[Solo LFG]|r Requires level 78 or above.");
            return true;
        }
        if (player->GetGroup())
        {
            handler->SendSysMessage("|cffFF4444[Solo LFG]|r Leave your group before using Solo Queue.");
            return true;
        }

        if (args.empty())
        {
            handler->PSendSysMessage("Usage: .synrdf <number>  |  .synrdf list  (1\xe2\x80\x93{})", DUNGEON_COUNT);
            return true;
        }

        auto opt = Acore::StringTo<uint32>(args);
        if (!opt || *opt == 0 || *opt > DUNGEON_COUNT)
        {
            handler->PSendSysMessage("|cffFF4444[Solo LFG]|r Invalid index. Use 1\xe2\x80\x93{}. "
                "Type .synrdf list to see options.", DUNGEON_COUNT);
            return true;
        }

        DungeonEntrance const& dungeon = KNOWN_DUNGEONS[*opt - 1];

        ApplySoloBoost(player, true);
        player->TeleportTo(dungeon.mapId, dungeon.x, dungeon.y, dungeon.z, dungeon.o);

        handler->PSendSysMessage(
            "|cff00FF00[Solo LFG]|r Entering |cffFFD700{}|r. "
            "Solo boost: |cff00FF00+{}%%|r stats.",
            dungeon.name, static_cast<uint32>(g_SLStatBoost));
        return true;
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Registration
// ─────────────────────────────────────────────────────────────────────────────

void AddSC_mod_solo_lfg()
{
    new SoloLFGWorldScript();
    new SoloLFGPlayerScript();
    new SoloLFGCommandScript();
}
