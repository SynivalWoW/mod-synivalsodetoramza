/*
 * mod-synival-ode-to-ramza — loader.cpp
 * Synival's Ode to Ramza
 *
 * AzerothCore requires one exported function whose name is derived from the
 * module folder name (hyphens → underscores, prefixed with "Add"):
 *
 *   Folder:   mod-synival-ode-to-ramza
 *   Function: Addmod_synival_ode_to_ramzaScripts()
 *
 * This file registers every subsystem in the combined module.
 * If something doesn't load, this is probably where to look first.
 *
 * ── Paragon systems (from mod-synival-paragon) ────────────────────────────
 *   1. Core Paragon system    — paragon XP, prestige, board, stats, NPCs
 *   2. Loot system            — tier rarity, scaling, auto-loot, legendaries
 *   3. Random Enchants        — weighted enchant pool on loot/craft
 *   4. Buff Command           — .synbuff <spell_id>
 *   5. Solo LFG               — .synqueue <dungeon>
 *   6. Skip DK Starting Area  — .synskipdk
 *   7. AutoBalance + OWB      — creature HP/damage scaling by player count
 *
 * ── Guild systems (from mod-guild-village + mod-dungeon-master + bridge) ──
 *   8.  Guild Village — ownership, upgrades, production, expeditions, quests
 *   9.  Dungeon Master — procedural dungeon challenges and roguelike mode
 *   10. Guild Sanctuary Bridge — Warden NPC, guild-tagged sessions, rewards
 *
 * ── Dungeon Respawn (AnchyDev/DungeonRespawn) ─────────────────────────────
 *   11. Dungeon Respawn — in-instance respawn at last recorded position
 */

#include "ScriptMgr.h"
#include "Log.h"

// ── Paragon system registrations ───────────────────────────────────────────
void AddSC_mod_synival_paragon();
void AddSC_mod_synival_loot();
void AddSC_mod_random_enchants();
void AddSC_mod_buff_command();
void AddSC_mod_solo_lfg();
void AddSC_mod_skip_dk();
void AddSC_mod_autobalance();

// ── Guild Village registrations ────────────────────────────────────────────
void RegisterGuildVillageCustomsUpdater();
void RegisterGuildVillageCommands();
void RegisterGuildVillageAoe();
void RegisterGuildVillageCreate();
void RegisterGuildVillageUpgrade();
void RegisterGuildVillageRespawn();
void RegisterGuildVillageLoot();
void RegisterGuildVillageGM();
void RegisterGuildVillageRest();
void RegisterGuildVillageDisband();
void RegisterGuildVillageWhere();
void RegisterGuildVillageBot();
void RegisterGuildVillageTeleporter();
void RegisterGuildVillageProduction();
void RegisterGuildVillagePvP();
void RegisterGuildVillageExpeditions();
void RegisterGuildVillageExpeditionsMissions();
void RegisterGuildVillageVoltrix();
void RegisterGuildVillageThranok();
void RegisterGuildVillageThalgron();
void RegisterGuildVillageThalor();
void RegisterGuildVillageQuests();
void RegisterGuildVillageQuestsWiring();

// ── Dungeon Master registrations ───────────────────────────────────────────
void AddSC_npc_dungeon_master();
void AddSC_dm_player_script();
void AddSC_dm_world_script();
void AddSC_dm_allmap_script();
void AddSC_dm_command_script();
void AddSC_dm_unit_script();

// ── Guild Village Periodic Reward ──────────────────────────────────────────
void RegisterGuildVillagePeriodicReward();

// ── Guild Sanctuary Bridge ─────────────────────────────────────────────────
void RegisterGuildSanctuaryDungeon();

// ── Dungeon Respawn ────────────────────────────────────────────────────────
void SC_AddDungeonRespawnScripts();

// ── Module entry point ─────────────────────────────────────────────────────
void Addmod_synival_ode_to_ramzaScripts()
{
    LOG_INFO("module", "OtR: Initialising Synival's Ode to Ramza...");

    // 1–7. Paragon systems
    AddSC_mod_synival_paragon();
    AddSC_mod_synival_loot();
    AddSC_mod_random_enchants();
    AddSC_mod_buff_command();
    AddSC_mod_solo_lfg();
    AddSC_mod_skip_dk();
    AddSC_mod_autobalance();

    // 8. Guild Village
    RegisterGuildVillageCustomsUpdater();
    RegisterGuildVillageCommands();
    RegisterGuildVillageAoe();
    RegisterGuildVillageCreate();
    RegisterGuildVillageUpgrade();
    RegisterGuildVillageRespawn();
    RegisterGuildVillageLoot();
    RegisterGuildVillageGM();
    RegisterGuildVillageRest();
    RegisterGuildVillageDisband();
    RegisterGuildVillageWhere();
    RegisterGuildVillageBot();
    RegisterGuildVillageTeleporter();
    RegisterGuildVillageProduction();
    RegisterGuildVillagePvP();
    RegisterGuildVillageExpeditions();
    RegisterGuildVillageExpeditionsMissions();
    RegisterGuildVillageVoltrix();
    RegisterGuildVillageThranok();
    RegisterGuildVillageThalgron();
    RegisterGuildVillageThalor();
    RegisterGuildVillageQuests();
    RegisterGuildVillageQuestsWiring();
    RegisterGuildVillagePeriodicReward();

    // 9. Dungeon Master
    AddSC_npc_dungeon_master();
    AddSC_dm_player_script();
    AddSC_dm_world_script();
    AddSC_dm_allmap_script();
    AddSC_dm_command_script();
    AddSC_dm_unit_script();

    // 10. Guild Sanctuary Bridge
    RegisterGuildSanctuaryDungeon();

    // 11. Dungeon Respawn
    SC_AddDungeonRespawnScripts();

    LOG_INFO("module", "OtR: Synival's Ode to Ramza loaded successfully.");
}
