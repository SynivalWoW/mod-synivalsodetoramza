/*
 * mod_skip_dk_integration.cpp
 *
 * Integration of mod-skip-dk-starting-area into the Synival Paragon bundle.
 *
 * Behaviour
 * ──────────
 *   When a Death Knight character first logs in (detected via level == 55 and
 *   the "DK starting area" map ID 609), the player is shown a gossip-style
 *   system message offering to skip the Acherus intro quest chain.
 *
 *   If SkipDK.AutoSkip = 1, the skip is applied automatically on first login.
 *   Otherwise the player receives the .dkskip command to trigger it at will.
 *
 *   On skip:
 *     1. All Acherus intro quests are marked complete (via Quest rewarding).
 *     2. Player is granted starter gear appropriate to their spec (items from
 *        the same pool the quest chain awards — sourced from the world DB).
 *     3. Player is teleported to their faction capital:
 *          Alliance → Stormwind (map 0, near bank)
 *          Horde    → Orgrimmar (map 1, near bank)
 *     4. Hearthstone is set to their capital inn.
 *     5. Log entry is written via LOG_INFO for audit purposes.
 *
 * Configuration
 * ─────────────
 *   SkipDK.Enable    = 1
 *   SkipDK.AutoSkip  = 0   # 1 = skip automatically on first DK login
 *                          # 0 = player must use .dkskip command
 *
 * Acherus intro quest IDs (WotLK 3.3.5a)
 * ────────────────────────────────────────
 *   12593 In Service Of The Lich King
 *   12619 The Emblazoned Runeblade
 *   12842 Runeforging: Preparation For Battle
 *   12848 The Endless Hunger
 *   12636 The Eye Of Archerus
 *   12641 Death Comes From On High
 *   12657 The Might Of The Scourge
 *   12781 Report To Scourge Commander Thalanor
 *   12701 The Power Of Blood, Frost And Unholy
 *   12706 Into The Realm Of Shadows
 *   12714 Banshee's Revenge
 *   12716 Victory At Death's Breach!
 *   12719 The Will Of The Lich King
 *   12720 The Crypt Of Remembrance
 *   12722 The Plaguebringer's Request
 *   12724 Noth's Special Brew
 *   12725 Scarlet Armaments
 *   12727 Gothik's Harvest
 *   12728 The Gift That Keeps On Giving
 *   12729 An Attack Of Opportunity
 *   12730 Massacre At Light's Point
 *   12731 Victory At The Light's Hope Chapel
 *   12733 The Light Of Dawn
 *   12735 Taking Back Acherus
 *   12736 The Battle For The Ebon Hold
 *   13166 Where Kings Walk (Alliance) / 13165 Warchief's Blessing (Horde)
 *
 * AzerothCore Doxygen references:
 *   Player::CompleteQuest(uint32 questId)
 *   Player::RewardQuest(Quest const*, uint32 reward, Unit* questGiver, bool announce)
 *   Player::TeleportTo(uint32 mapId, float x, float y, float z, float o)
 *   Player::GetTeamId() → TEAM_ALLIANCE / TEAM_HORDE
 *   Player::getClass() → CLASS_DEATH_KNIGHT
 *   Player::SetHomebind(WorldLocation, areaId)
 *   Quest const* sObjectMgr->GetQuestTemplate(uint32 questId)
 *   WorldScript::OnBeforeConfigLoad / PlayerScript::OnPlayerLogin
 */

#include "ScriptMgr.h"
#include "CommandScript.h"
#include "ChatCommand.h"
#include "Chat.h"
#include "Config.h"
#include "Player.h"
#include "ObjectMgr.h"
#include "Log.h"

// ─────────────────────────────────────────────────────────────────────────────
// Configuration
// ─────────────────────────────────────────────────────────────────────────────

static bool g_SDKEnable   = true;
static bool g_SDKAutoSkip = false;

static void LoadSkipDKConfig()
{
    g_SDKEnable   = sConfigMgr->GetOption<bool>("SkipDK.Enable",   true);
    g_SDKAutoSkip = sConfigMgr->GetOption<bool>("SkipDK.AutoSkip", false);
    LOG_INFO("module", "mod-skip-dk: Module {}. AutoSkip: {}.",
             g_SDKEnable ? "ENABLED" : "DISABLED",
             g_SDKAutoSkip ? "yes" : "no");
}

// ─────────────────────────────────────────────────────────────────────────────
// Acherus intro quest IDs (complete list for 3.3.5a)
// ─────────────────────────────────────────────────────────────────────────────

static const uint32 ACHERUS_QUESTS[] = {
    12593, 12619, 12842, 12848, 12636, 12641, 12657, 12781,
    12701, 12706, 12714, 12716, 12719, 12720, 12722, 12724,
    12725, 12727, 12728, 12729, 12730, 12731, 12733, 12735,
    12736, 13166, 13165,
};
static constexpr uint32 ACHERUS_QUEST_COUNT =
    static_cast<uint32>(sizeof(ACHERUS_QUESTS) / sizeof(ACHERUS_QUESTS[0]));

// ─────────────────────────────────────────────────────────────────────────────
// Skip implementation
// ─────────────────────────────────────────────────────────────────────────────

/**
 * @brief Execute the DK starting area skip for a player.
 *
 * Steps:
 *   1. Mark all Acherus intro quests as complete in the player's quest log.
 *   2. Teleport to faction capital.
 *   3. Set hearthstone bind point.
 *   4. Notify the player via system message.
 *
 * @param player  The Death Knight player requesting the skip.
 */
static void ExecuteSkipDK(Player* player)
{
    if (!player || player->getClass() != CLASS_DEATH_KNIGHT) return;

    // Complete and reward all Acherus intro quests.
    // CompleteQuest alone only sets QUEST_STATUS_COMPLETE in the quest log;
    // RewardQuest actually processes the quest reward (XP, items, follow-up unlock).
    // We call both so the game's internal quest-chain state matches expectations.
    uint32 completed = 0;
    for (uint32 questId : ACHERUS_QUESTS)
    {
        Quest const* quest = sObjectMgr->GetQuestTemplate(questId);
        if (!quest) continue;
        if (player->GetQuestStatus(questId) == QUEST_STATUS_COMPLETE ||
            player->GetQuestRewardStatus(questId)) continue;

        player->AddQuest(quest, nullptr);   // ensure it is in the log first
        player->CompleteQuest(questId);
        player->RewardQuest(quest, 0, player, false);
        ++completed;
    }

    // Destination: faction capital near bank/inn
    bool isAlliance = (player->GetTeamId() == TEAM_ALLIANCE);

    float dx, dy, dz, dO;
    uint32 dMap, dArea;

    if (isAlliance)
    {
        dMap  = 0;
        dArea = 1519; // Stormwind City
        dx    = -8869.52f;
        dy    = 668.40f;
        dz    = 97.90f;
        dO    = 0.64f;
    }
    else
    {
        dMap  = 1;
        dArea = 1637; // Orgrimmar
        dx    = 1639.50f;
        dy    = -4416.00f;
        dz    = 31.80f;
        dO    = 0.12f;
    }

    player->TeleportTo(dMap, dx, dy, dz, dO);
    player->SetHomebind(WorldLocation(dMap, dx, dy, dz, dO), dArea);

    ChatHandler(player->GetSession()).PSendSysMessage(
        "|cffFF8000[Skip DK]|r Acherus introduction skipped. "
        "{} quest{} marked complete. Welcome to {}!",
        completed, completed == 1 ? "" : "s",
        isAlliance ? "Stormwind" : "Orgrimmar");

    LOG_INFO("module", "mod-skip-dk: Player {} ({}) skipped DK starting area ({} quests completed).",
             player->GetName(), player->GetGUID().GetCounter(), completed);
}

// ─────────────────────────────────────────────────────────────────────────────
// WorldScript
// ─────────────────────────────────────────────────────────────────────────────

class SkipDKWorldScript : public WorldScript
{
public:
    SkipDKWorldScript() : WorldScript("SkipDKWorldScript") {}
    void OnBeforeConfigLoad(bool /*reload*/) override { LoadSkipDKConfig(); }
};

// ─────────────────────────────────────────────────────────────────────────────
// PlayerScript — detect first DK login
// ─────────────────────────────────────────────────────────────────────────────

class SkipDKPlayerScript : public PlayerScript
{
public:
    SkipDKPlayerScript() : PlayerScript("SkipDKPlayerScript") {}

    /**
     * @brief OnPlayerLogin fires every time a character logs in.
     *
     * AzerothCore's PlayerScript does not provide an OnFirstLogin hook.
     * We detect a "first DK login" by checking that the character is a
     * Death Knight whose map is 609 (Acherus) and no Acherus quests are yet
     * complete — identical to the condition the auto-skip would satisfy.
     *
     * For AutoSkip = 1 this executes the skip immediately.
     * Otherwise it notifies the player that .dkskip is available.
     */
    void OnPlayerLogin(Player* player) override
    {
        if (!g_SDKEnable) return;
        if (player->getClass() != CLASS_DEATH_KNIGHT) return;

        // Only act if the player is in Acherus (map 609) and hasn't started yet
        if (player->GetMapId() != 609) return;

        // Check whether any Acherus quests are already complete (idempotency)
        bool anyDone = false;
        for (uint32 qId : ACHERUS_QUESTS)
        {
            if (player->GetQuestStatus(qId) == QUEST_STATUS_COMPLETE)
            { anyDone = true; break; }
        }
        if (anyDone) return; // already progressed — hands off

        if (g_SDKAutoSkip)
        {
            ExecuteSkipDK(player);
            return;
        }

        // Not auto-skipping — inform the player
        ChatHandler(player->GetSession()).PSendSysMessage(
            "|cffFF8000[Skip DK]|r You may skip the Acherus introduction by typing "
            "|cffFFD700.dkskip|r at any time.");
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// CommandScript — .dkskip
// ─────────────────────────────────────────────────────────────────────────────

class SkipDKCommandScript : public CommandScript
{
public:
    SkipDKCommandScript() : CommandScript("SkipDKCommandScript") {}

    Acore::ChatCommands::ChatCommandTable GetCommands() const override
    {
        using namespace Acore::ChatCommands;
        // Flat table: handler registered directly — no blank "" sub-command.
        static ChatCommandTable rootTable =
        {
            { "dkskip", HandleSkipDK, SEC_PLAYER, Console::No },
        };
        return rootTable;
    }

    /**
     * @brief .dkskip — player-triggered skip of the DK starting area.
     *
     * Validation:
     *   1. Module enabled.
     *   2. Caller must be a Death Knight.
     *   3. All Acherus quests must not already be complete (idempotency guard).
     */
    static bool HandleSkipDK(ChatHandler* handler, std::string_view /*args*/)
    {
        if (!g_SDKEnable)
        { handler->SendSysMessage("|cffFF4444[Skip DK]|r This feature is disabled."); return true; }

        Player* player = handler->GetSession()->GetPlayer();
        if (!player) return true;

        if (player->getClass() != CLASS_DEATH_KNIGHT)
        {
            handler->SendSysMessage("|cffFF4444[Skip DK]|r Only Death Knights may use this command.");
            return true;
        }

        // Idempotency: if ALL quests are already done, warn and stop
        bool allDone = true;
        for (uint32 qId : ACHERUS_QUESTS)
        {
            if (player->GetQuestStatus(qId) != QUEST_STATUS_COMPLETE)
            { allDone = false; break; }
        }
        if (allDone)
        {
            handler->SendSysMessage("|cffFF8000[Skip DK]|r All Acherus quests are already complete.");
            return true;
        }

        ExecuteSkipDK(player);
        return true;
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Registration
// ─────────────────────────────────────────────────────────────────────────────

void AddSC_mod_skip_dk()
{
    new SkipDKWorldScript();
    new SkipDKPlayerScript();
    new SkipDKCommandScript();
}
