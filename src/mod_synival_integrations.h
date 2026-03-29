#pragma once
/*
 * mod_synival_integrations.h
 *
 * Declarations for the four AzerothCore community modules integrated into
 * the Synival Paragon bundle. Each sub-module is self-contained in its own
 * class registration; they share only this header for forward declarations.
 *
 * Integrated modules
 * ──────────────────
 *  1. Random Enchants  — based on mod-random-enchants (azerothcore)
 *     Applies a random permanent enchantment from a configurable pool to
 *     weapons and armour as they are looted, crafted, or received from quests.
 *     Config key prefix: RandomEnchants.*
 *
 *  2. Buff Command     — based on mod-buff-command (azerothcore)
 *     Adds a .buff <spell_id> command. Players may self-buff with a whitelist
 *     of spells defined in the config. Administrators may buff any target.
 *     Config key prefix: BuffCommand.*
 *
 *  3. Solo LFG         — based on mod-solo-lfg (azerothcore)
 *     Allows a single player to queue for LFG dungeons without needing a full
 *     group. Scales group rewards so the solo player is not penalised.
 *     Config key prefix: SoloLFG.*
 *
 *  4. Skip DK Starting Area — based on mod-skip-dk-starting-area (azerothcore)
 *     On creation of a Death Knight character, offers the player a choice to
 *     skip the Acherus intro chain and spawn directly in Stormwind/Orgrimmar
 *     at level 58 with starter gear.
 *     Config key prefix: SkipDK.*
 *
 * AzerothCore Doxygen references used throughout the implementation:
 *   Player::LearnSpell / RemoveSpell
 *   Player::TeleportTo
 *   Player::GetSession / WorldSession::GetSecurity
 *   Player::getClass / getLevel / GetTeamId
 *   Player::AddItem / StoreNewItem / CanStoreNewItem
 *   CreatureScript / PlayerScript / WorldScript / CommandScript
 *   ScriptMgr hook: OnPlayerLootItem, OnLogin, OnGiveXP, OnPlayerCreate
 *   ChatHandler / PSendSysMessage / SendSysMessage
 *   sConfigMgr->GetOption<T>
 *   roll_chance_i / urand
 *   ObjectMgr::GetSpellInfo / sSpellMgr
 *   LFGMgr / sLFGMgr (LFG queue management)
 */

void AddSC_mod_random_enchants();
void AddSC_mod_buff_command();
void AddSC_mod_solo_lfg();
void AddSC_mod_skip_dk();
