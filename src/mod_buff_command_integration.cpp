/*
 * mod_buff_command_integration.cpp
 *
 * Provides two commands:
 *
 *   .playerbuff
 *     Applies all class-specific buffs for the caster's class.
 *     Uses triggered CastSpell (no reagent, no range check).
 *     Buffs applied per class:
 *       All classes    : Gift of the Wild, Prayer of Fortitude, Prayer of Spirit,
 *                        Prayer of Shadow Protection
 *       Warrior        : Battle Shout (rank 8), Commanding Shout
 *       Paladin        : Greater Blessing of Kings, Greater Blessing of Might,
 *                        Greater Blessing of Sanctuary, Greater Blessing of Wisdom
 *       Hunter         : Aspect of the Pack (movement) — skipped (causes daze)
 *       Death Knight   : Horn of Winter
 *       Druid          : Gift of the Wild (already in all-class list)
 *       Mage           : Arcane Brilliance
 *       Priest         : already covered by Prayer buffs above
 *
 *   .learnbuffs
 *     Teaches the player ALL class-specific buff spells from every class
 *     (all ranks) that they do not already know. This lets any player
 *     cast any group buff regardless of their class.
 *
 * AzerothCore references:
 *   Player::CastSpell(Unit*, uint32, bool triggered)
 *   Player::learnSpell(uint32, bool)
 *   Player::HasSpell(uint32)
 *   sSpellMgr->GetSpellInfo(uint32)
 *   CommandScript / ChatCommandTable
 */

#include "ScriptMgr.h"
#include "CommandScript.h"
#include "ChatCommand.h"
#include "Chat.h"
#include "Config.h"
#include "Player.h"
#include "SpellMgr.h"
#include "Log.h"
#include <vector>

// ─────────────────────────────────────────────────────────────────────────────
// Config
// ─────────────────────────────────────────────────────────────────────────────

static bool g_BCEnable = true;

static void LoadBuffCommandConfig()
{
    g_BCEnable = sConfigMgr->GetOption<bool>("BuffCommand.Enable", true);
    LOG_INFO("module", "mod-buff-command: Module {}.", g_BCEnable ? "ENABLED" : "DISABLED");
}

// ─────────────────────────────────────────────────────────────────────────────
// Buff tables
// ─────────────────────────────────────────────────────────────────────────────

// All-class buffs — applied to every player regardless of class
static const uint32 BUFFS_ALL[] =
{
    48470,  // Gift of the Wild III    (Druid — group Mark of the Wild)
    48162,  // Prayer of Fortitude III (Priest — group Fortitude)
    48074,  // Prayer of Spirit II     (Priest — group Spirit)
    39374,  // Prayer of Shadow Protection II (Priest — group shadow resist)
};

// Per-class additional buffs
// WoW class IDs: 1=Warrior 2=Paladin 3=Hunter 4=Rogue 5=Priest
//                6=DK 7=Shaman 8=Mage 9=Warlock 11=Druid
struct ClassBuffSet { uint8 classId; std::vector<uint32> spells; };

static const ClassBuffSet CLASS_BUFFS[] =
{
    { 1,  { 47436,  // Battle Shout VIII      (Warrior — AP bonus)
            47440 } // Commanding Shout III   (Warrior — Stamina)
    },
    { 2,  { 25898,  // Greater Blessing of Kings (Paladin)
            48934,  // Greater Blessing of Might II (Paladin)
            25899,  // Greater Blessing of Sanctuary (Paladin)
            48938 } // Greater Blessing of Wisdom II (Paladin)
    },
    { 6,  { 57623 } // Horn of Winter II (Death Knight)
    },
    { 7,  { 58086 } // Strength of Earth Totem VIII (Shaman — passive via totem)
    },
    { 8,  { 43002 } // Arcane Brilliance (Mage — group Intellect)
    },
};

// ─────────────────────────────────────────────────────────────────────────────
// All buff spells from every class — for .learnbuffs
// All ranks included so players have the full spell chain.
// ─────────────────────────────────────────────────────────────────────────────
static const uint32 ALL_BUFF_SPELLS[] =
{
    // ── Warrior ──────────────────────────────────────────────────────────
    6673, 5242, 6192, 11549, 11550, 11551, 25289, 2048, 47436,   // Battle Shout ranks 1-8 + 9
    469,  2048, 6192, 11551, 47436,                               // (dedup handled by HasSpell)
    5765, 6190, 11552, 11553, 25202, 47440,                       // Commanding Shout ranks
    // ── Paladin ──────────────────────────────────────────────────────────
    20217, 20218, 20219, 20220, 20221, 25898,                     // Blessing of Kings / Greater
    19740, 19834, 19835, 19836, 19837, 19838, 25291, 48932, 48934,// Blessing of Might / Greater
    20911, 20912, 20913, 20914, 20915, 27140, 33330, 48935, 48936,// Blessing of Wisdom / Greater
    20914, 25899,                                                  // Blessing of Sanctuary / Greater
    // ── Druid ────────────────────────────────────────────────────────────
    1126, 5232, 6756, 5234, 8907, 9884, 9885, 26990, 48469,      // Mark of the Wild ranks
    21849, 21850, 26991, 48470,                                    // Gift of the Wild ranks
    // ── Priest ───────────────────────────────────────────────────────────
    1243, 1244, 1245, 2791, 10937, 10938, 25389, 48161, 48162,   // Power Word: Fortitude
    21562, 21564, 25392, 48162,                                    // Prayer of Fortitude
    14752, 14818, 14819, 27841, 48073, 48074,                     // Prayer of Spirit
    32999, 39374,                                                  // Prayer of Shadow Protection
    976,  10957, 10958, 27683, 39374,                             // (dedup ok)
    // ── Mage ─────────────────────────────────────────────────────────────
    1459, 1460, 1461, 10156, 10157, 27126, 42995, 43002,          // Arcane Intellect ranks
    23028, 27127, 43002,                                           // Arcane Brilliance ranks
    // ── Death Knight ─────────────────────────────────────────────────────
    57330, 57623,                                                   // Horn of Winter ranks
    // ── Shaman ───────────────────────────────────────────────────────────
    8076, 8162, 8163, 10442, 25361, 25528, 57621,                 // Strength of Earth Totem
    // ── Warlock ──────────────────────────────────────────────────────────
    // No group buffs in WotLK
};

// ─────────────────────────────────────────────────────────────────────────────
// WorldScript
// ─────────────────────────────────────────────────────────────────────────────

class BuffCommandWorldScript : public WorldScript
{
public:
    BuffCommandWorldScript() : WorldScript("BuffCommandWorldScript") {}
    void OnBeforeConfigLoad(bool /*reload*/) override { LoadBuffCommandConfig(); }
};

// ─────────────────────────────────────────────────────────────────────────────
// CommandScript
// ─────────────────────────────────────────────────────────────────────────────

class SynivalBuffCommandScript : public CommandScript
{
public:
    SynivalBuffCommandScript() : CommandScript("SynivalBuffCommandScript") {}

    Acore::ChatCommands::ChatCommandTable GetCommands() const override
    {
        using namespace Acore::ChatCommands;
        static ChatCommandTable rootTable =
        {
            { "playerbuff", HandlePlayerBuff, SEC_PLAYER, Console::No },
            { "learnbuffs", HandleLearnBuffs, SEC_PLAYER, Console::No },
        };
        return rootTable;
    }

    /**
     * @brief .playerbuff
     * Casts all class-appropriate group buffs on the player using triggered
     * CastSpell (bypasses reagent and range requirements).
     */
    static bool HandlePlayerBuff(ChatHandler* handler, std::string_view /*args*/)
    {
        if (!g_BCEnable)
        { handler->SendSysMessage("|cffFF4444[Buff]|r This feature is disabled."); return true; }

        Player* player = handler->GetSession()->GetPlayer();
        if (!player) return true;

        uint32 count = 0;

        // Apply all-class buffs
        for (uint32 spellId : BUFFS_ALL)
        {
            if (sSpellMgr->GetSpellInfo(spellId))
            {
                player->CastSpell(player, spellId, true);
                ++count;
            }
        }

        // Apply class-specific buffs
        uint8 playerClass = player->getClass();
        for (auto const& set : CLASS_BUFFS)
        {
            if (set.classId != playerClass) continue;
            for (uint32 spellId : set.spells)
            {
                if (sSpellMgr->GetSpellInfo(spellId))
                {
                    player->CastSpell(player, spellId, true);
                    ++count;
                }
            }
        }

        handler->PSendSysMessage(
            "|cff00FF00[Buff]|r Applied {} buff{} for your class.",
            count, count == 1 ? "" : "s");
        return true;
    }

    /**
     * @brief .learnbuffs
     * Teaches all class-specific buff spells from every class (all ranks)
     * that the player does not already know. Available to all players.
     */
    static bool HandleLearnBuffs(ChatHandler* handler, std::string_view /*args*/)
    {
        if (!g_BCEnable)
        { handler->SendSysMessage("|cffFF4444[Buff]|r This feature is disabled."); return true; }

        Player* player = handler->GetSession()->GetPlayer();
        if (!player) return true;

        uint32 learned = 0;
        for (uint32 spellId : ALL_BUFF_SPELLS)
        {
            if (!sSpellMgr->GetSpellInfo(spellId)) continue;
            if (player->HasSpell(spellId)) continue;
            player->learnSpell(spellId);
            ++learned;
        }

        if (learned > 0)
            handler->PSendSysMessage(
                "|cff00FF00[Learn Buffs]|r Learned {} new buff spell{}. "
                "Check your spellbook.",
                learned, learned == 1 ? "" : "s");
        else
            handler->SendSysMessage(
                "|cffFFD700[Learn Buffs]|r You already know all class buff spells.");

        return true;
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// Registration
// ─────────────────────────────────────────────────────────────────────────────

void AddSC_mod_buff_command()
{
    new BuffCommandWorldScript();
    new SynivalBuffCommandScript();
}
