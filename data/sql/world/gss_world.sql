-- ============================================================
-- mod-synival-guild-sanctuary | world database
-- ============================================================
-- Run against your WORLD database before starting the server.
--
-- This file creates:
--   1. creature_template entry 501000 — Warden of the Vault (gossip NPC)
--   2. creature_template_model entry  — display model for the Warden
--   3. npc_text entry 501000          — gossip greeting text
--
-- NOTE: The Warden does NOT have a static creature row in this file.
--   She is spawned dynamically inside each guild village by the
--   guild_village_create.cpp InstallBaseLayout() call, using a row in
--   customs.gv_creature_template with layout_key='base' and entry=501000.
--   See 004_gss_gv_creature_template.sql in the customs/base folder.
--
-- Entry ID range used by this module: 501000–501099
-- ============================================================

-- ── Warden of the Vault (entry 501000) ────────────────────────────────────
DELETE FROM `creature_template_model` WHERE `CreatureID` = 501000;
DELETE FROM `creature_template`       WHERE `entry`      = 501000;

INSERT INTO `creature_template` (
    `entry`,
    `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`,
    `KillCredit1`, `KillCredit2`,
    `name`, `subname`, `IconName`,
    `gossip_menu_id`,
    `minlevel`, `maxlevel`,
    `exp`,
    `faction`,
    `npcflag`,
    `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`,
    `detection_range`,
    `scale`,
    `rank`,
    `dmgschool`,
    `BaseAttackTime`, `RangeAttackTime`,
    `BaseVariance`, `RangeVariance`,
    `unit_class`,
    `unit_flags`, `unit_flags2`,
    `dynamicflags`,
    `family`,
    `type`, `type_flags`,
    `lootid`, `pickpocketloot`, `skinloot`,
    `PetSpellDataId`, `VehicleId`,
    `mingold`, `maxgold`,
    `AIName`,
    `MovementType`,
    `HoverHeight`,
    `HealthModifier`, `ManaModifier`, `ArmorModifier`,
    `DamageModifier`, `ExperienceModifier`,
    `RacialLeader`,
    `movementId`,
    `RegenHealth`,
    `mechanic_immune_mask`, `spell_school_immune_mask`,
    `flags_extra`,
    `ScriptName`,
    `VerifiedBuild`
) VALUES (
    501000,
    0, 0, 0,
    0, 0,
    'Warden of the Vault', 'Guild Sanctuary', 'Speak',
    501000,             -- gossip_menu_id → npc_text.ID below
    80, 80,
    2,                  -- exp = 2 (WotLK)
    35,                 -- faction 35 = friendly to all
    1,                  -- UNIT_NPC_FLAG_GOSSIP
    1.0, 1.14286, 1.0, 1.0,
    20.0,
    1.1,                -- slightly taller than default
    0,                  -- Normal rank
    0,                  -- SPELL_SCHOOL_NORMAL
    2000, 2000,
    1.0, 1.0,
    1,                  -- unit_class = Warrior (health only)
    2, 0,               -- unit_flags = NON_ATTACKABLE
    0,
    0,
    7, 0,               -- type = Humanoid
    0, 0, 0,
    0, 0,
    0, 0,
    'ReactorAI',        -- passive: won't fight back
    0,                  -- Idle
    1.0,
    1.0, 1.0, 1.0,
    1.0, 1.0,
    0,
    0,
    1,
    0, 0,
    16777216,           -- CREATURE_FLAG_EXTRA_MODULE
    'npc_guild_sanctuary_warden',
    0
);

-- ── Display model ──────────────────────────────────────────────────────────
-- DisplayID 19833 = Female Night Elf in plate armour (generic captain).
-- Safe, faction-neutral appearance on a stock 3.3.5a client.
INSERT INTO `creature_template_model` (
    `CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`
) VALUES (
    501000, 0, 19833, 1.0, 1.0
);

-- ── npc_text ───────────────────────────────────────────────────────────────
-- Full column list per AzerothCore wiki schema.
-- Probability0 = 1 so the engine always selects text slot 0.
DELETE FROM `npc_text` WHERE `ID` = 501000;
INSERT INTO `npc_text` (
    `ID`,
    `text0_0`, `text0_1`,
    `lang0`, `Probability0`,
    `em0_0`, `em0_1`, `em0_2`, `em0_3`, `em0_4`, `em0_5`,
    `text1_0`, `text1_1`, `lang1`, `Probability1`,
    `em1_0`, `em1_1`, `em1_2`, `em1_3`, `em1_4`, `em1_5`,
    `text2_0`, `text2_1`, `lang2`, `Probability2`,
    `em2_0`, `em2_1`, `em2_2`, `em2_3`, `em2_4`, `em2_5`,
    `text3_0`, `text3_1`, `lang3`, `Probability3`,
    `em3_0`, `em3_1`, `em3_2`, `em3_3`, `em3_4`, `em3_5`,
    `text4_0`, `text4_1`, `lang4`, `Probability4`,
    `em4_0`, `em4_1`, `em4_2`, `em4_3`, `em4_4`, `em4_5`,
    `text5_0`, `text5_1`, `lang5`, `Probability5`,
    `em5_0`, `em5_1`, `em5_2`, `em5_3`, `em5_4`, `em5_5`,
    `text6_0`, `text6_1`, `lang6`, `Probability6`,
    `em6_0`, `em6_1`, `em6_2`, `em6_3`, `em6_4`, `em6_5`,
    `text7_0`, `text7_1`, `lang7`, `Probability7`,
    `em7_0`, `em7_1`, `em7_2`, `em7_3`, `em7_4`, `em7_5`,
    `VerifiedBuild`
) VALUES (
    501000,
    'The Vault stirs, $N. Your guild''s foes await within — shall we begin?',
    'The Vault stirs, $N. Your guild''s foes await within — shall we begin?',
    0, 1,
    0, 0, 0, 0, 0, 0,
    NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0,
    NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0,
    NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0,
    NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0,
    NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0,
    NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0,
    NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0,
    0
);
