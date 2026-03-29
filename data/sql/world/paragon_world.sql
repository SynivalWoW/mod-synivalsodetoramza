-- ============================================================
-- mod-synival-paragon | world database
-- ============================================================
-- Run against your WORLD database before starting the server.
--
-- Schema references used for every INSERT in this file:
--   creature_template : https://www.azerothcore.org/wiki/creature_template
--   creature          : https://www.azerothcore.org/wiki/creature
--   npc_text          : https://www.azerothcore.org/wiki/npc_text
--   item_template     : https://www.azerothcore.org/wiki/item_template
--
-- Entry ID ranges used by this module: 99200 – 99999
-- Verify these do not conflict with other modules on your server.
-- ============================================================


-- ============================================================
-- creature_template
-- ============================================================
-- Column order and types follow the wiki schema exactly.
-- All columns are supplied — no reliance on implicit defaults.
--
-- Corrections vs. previous version:
--   • Removed non-existent column  InhabitType
--   • Added all missing required columns with correct types:
--       difficulty_entry_1/2/3, KillCredit1/2, exp,
--       speed_swim, speed_flight, detection_range,
--       unit_flags2, type_flags, pickpocketloot, skinloot,
--       PetSpellDataId, VehicleId, BaseVariance, RangeVariance,
--       HealthModifier, ManaModifier, ArmorModifier,
--       DamageModifier, ExperienceModifier, RacialLeader,
--       movementId, RegenHealth, mechanic_immune_mask,
--       spell_school_immune_mask, flags_extra, VerifiedBuild
--   • flags_extra = 16777216 sets CREATURE_FLAG_EXTRA_MODULE
--     on all three custom NPCs so the core skips blizzlike
--     checks on them (per wiki flag table)
--   • exp = 2 (Wrath of the Lich King) for correct class stats
-- ============================================================

-- ── Runic Archive (entry 99996) ────────────────────────────
-- Gossip NPC. npcflag = 1 (UNIT_NPC_FLAG_GOSSIP).
-- faction = 35 (friendly to all players).
-- type = 7 (Humanoid). unit_class = 1 (Warrior — health only).
-- DisplayID = 1892 (Mountaineer Kadrell, entry 1340) — armed Ironforge dwarf in plate.
DELETE FROM `creature_template` WHERE `entry` = 99996;
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
    99996,              -- entry
    0, 0, 0,            -- difficulty_entry_1/2/3
    0, 0,               -- KillCredit1/2
    'Runic Archive', 'Paragon System', 'Speak',
    99996,              -- gossip_menu_id (matches npc_text.ID below)
    80, 80,             -- minlevel / maxlevel
    2,                  -- exp = 2 (WotLK)
    35,                 -- faction (friendly to all)
    1,                  -- npcflag: 1 = UNIT_NPC_FLAG_GOSSIP
    1.0, 1.14286, 1.0, 1.0,  -- speed_walk / run / swim / flight
    20.0,               -- detection_range
    1.2,                -- scale
    0,                  -- rank (Normal)
    0,                  -- dmgschool (SPELL_SCHOOL_NORMAL)
    2000, 2000,         -- BaseAttackTime / RangeAttackTime (ms)
    1.0, 1.0,           -- BaseVariance / RangeVariance
    1,                  -- unit_class (CLASS_WARRIOR — health only)
    2, 0,               -- unit_flags: 2 = UNIT_FLAG_NON_ATTACKABLE; unit_flags2 = 0
    0,                  -- dynamicflags
    0,                  -- family (none)
    7, 0,               -- type = 7 (Humanoid); type_flags = 0
    0, 0, 0,            -- lootid / pickpocketloot / skinloot
    0, 0,               -- PetSpellDataId / VehicleId
    0, 0,               -- mingold / maxgold
    'ReactorAI',        -- AIName (passive — doesn't fight back)
    0,                  -- MovementType (0 = Idle)
    1.0,                -- HoverHeight
    1.0, 1.0, 1.0,      -- HealthModifier / ManaModifier / ArmorModifier
    1.0, 1.0,           -- DamageModifier / ExperienceModifier
    0,                  -- RacialLeader
    0,                  -- movementId
    1,                  -- RegenHealth
    0, 0,               -- mechanic_immune_mask / spell_school_immune_mask
    16777216,           -- flags_extra: CREATURE_FLAG_EXTRA_MODULE
    'npc_runic_archive',
    0                   -- VerifiedBuild
);

-- ── Kadala, Purveyor of Mystery (entry 99998) ──────────────
-- Gossip NPC. npcflag = 1 (UNIT_NPC_FLAG_GOSSIP).
-- DisplayID = 30893 (Lady Deathwhisper, entry 36855) — hooded ICC female raid boss,
-- mysterious and commanding, perfectly fitting for a "Purveyor of Mystery".
DELETE FROM `creature_template` WHERE `entry` = 99998;
INSERT INTO `creature_template` (
    `entry`,
    `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`,
    `KillCredit1`, `KillCredit2`,
    `name`, `subname`, `IconName`,
    `gossip_menu_id`,
    `minlevel`, `maxlevel`,
    `exp`, `faction`, `npcflag`,
    `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`,
    `detection_range`, `scale`, `rank`, `dmgschool`,
    `BaseAttackTime`, `RangeAttackTime`,
    `BaseVariance`, `RangeVariance`,
    `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`,
    `family`, `type`, `type_flags`,
    `lootid`, `pickpocketloot`, `skinloot`,
    `PetSpellDataId`, `VehicleId`,
    `mingold`, `maxgold`,
    `AIName`, `MovementType`, `HoverHeight`,
    `HealthModifier`, `ManaModifier`, `ArmorModifier`,
    `DamageModifier`, `ExperienceModifier`,
    `RacialLeader`, `movementId`, `RegenHealth`,
    `mechanic_immune_mask`, `spell_school_immune_mask`,
    `flags_extra`, `ScriptName`, `VerifiedBuild`
) VALUES (
    99998,
    0, 0, 0,
    0, 0,
    'Kadala', 'Purveyor of Mystery', 'Speak',
    99998,
    80, 80,
    2, 35, 1,
    1.0, 1.14286, 1.0, 1.0,
    20.0, 1.0, 0, 0,
    2000, 2000,
    1.0, 1.0,
    1, 2, 0, 0,
    0, 7, 0,
    0, 0, 0,
    0, 0,
    0, 0,
    'ReactorAI', 0, 1.0,
    1.0, 1.0, 1.0,
    1.0, 1.0,
    0, 0, 1,
    0, 0,
    16777216, 'npc_kadala_gamble', 0
);

-- ── The Butcher (entry 99997) ───────────────────────────────
-- World boss. Summoned dynamically at Prestige 10.
-- rank = 3 (Boss). type = 6 (Undead). AggressorAI.
-- npcflag = 0 (not interactive — pure combat NPC).
-- unit_flags = 0 (fully attackable).
-- type_flags = 4 sets the "??" skull level frame on the portrait.
-- faction = 21 (Undead Scourge) — hostile to all players, same as Lord Marrowgar.
-- DisplayID = 31119 (Lord Marrowgar model — enormous bone construct, visually menacing).
DELETE FROM `creature_template` WHERE `entry` = 99997;
INSERT INTO `creature_template` (
    `entry`,
    `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`,
    `KillCredit1`, `KillCredit2`,
    `name`, `subname`, `IconName`,
    `gossip_menu_id`,
    `minlevel`, `maxlevel`,
    `exp`, `faction`, `npcflag`,
    `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`,
    `detection_range`, `scale`, `rank`, `dmgschool`,
    `BaseAttackTime`, `RangeAttackTime`,
    `BaseVariance`, `RangeVariance`,
    `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`,
    `family`, `type`, `type_flags`,
    `lootid`, `pickpocketloot`, `skinloot`,
    `PetSpellDataId`, `VehicleId`,
    `mingold`, `maxgold`,
    `AIName`, `MovementType`, `HoverHeight`,
    `HealthModifier`, `ManaModifier`, `ArmorModifier`,
    `DamageModifier`, `ExperienceModifier`,
    `RacialLeader`, `movementId`, `RegenHealth`,
    `mechanic_immune_mask`, `spell_school_immune_mask`,
    `flags_extra`, `ScriptName`, `VerifiedBuild`
) VALUES (
    99997,
    0, 0, 0,
    0, 0,
    'The Butcher', 'Reborn in Crimson', 'Attack',
    0,
    82, 82,
    2, 21, 0,
    1.0, 1.14286, 1.0, 1.0,
    30.0, 2.0, 3, 0,
    2000, 2000,
    1.0, 1.0,
    1, 0, 0, 0,
    0, 6, 4,
    0, 0, 0,
    0, 0,
    0, 0,
    'AggressorAI', 0, 1.0,
    50.0, 1.0, 10.0,
    5.0, 0.0,
    0, 0, 1,
    0, 0,
    16777216, '', 0
);


-- ============================================================
-- creature  (individual spawn records)
-- ============================================================
-- Column order and types follow the wiki schema exactly.
--
-- Corrections vs. previous version:
--   • Column `id` renamed to `id1` (correct wiki name)
--   • Added `id2` and `id3` (both 0 — single template per spawn)
--   • Removed non-existent column `modelid`
--   • Added `ScriptName` (NULL — template ScriptName is used)
--   • Added `VerifiedBuild` (NULL)
--   • Added `CreateObject`  (0)
--   • Added `Comment` with descriptive text
--   • `equipment_id` = 0 (no equipment override)
--   • `npcflag`, `unit_flags`, `dynamicflags` = 0 (no override;
--     creature_template values are authoritative)
--   • `spawntimesecs` = 300 (5 min — standard AC default for rank 0)
--   • `curhealth` = 1, `curmana` = 0 per wiki "always set as 1/0"
-- ============================================================

-- ── Runic Archive spawn (Dalaran — near Krasus' Landing) ───
DELETE FROM `creature` WHERE `id1` = 99996;
INSERT INTO `creature` (
    `id1`, `id2`, `id3`,
    `map`, `zoneId`, `areaId`,
    `spawnMask`, `phaseMask`,
    `equipment_id`,
    `position_x`, `position_y`, `position_z`, `orientation`,
    `spawntimesecs`,
    `wander_distance`,
    `currentwaypoint`,
    `curhealth`, `curmana`,
    `MovementType`,
    `npcflag`, `unit_flags`, `dynamicflags`,
    `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`
) VALUES (
    99996, 0, 0,
    571, 0, 0,        -- map 571 = Dalaran; zoneId/areaId filled by core
    1, 1,             -- spawnMask = 1 (normal); phaseMask = 1 (phase 1)
    0,                -- equipment_id = 0 (none)
    5813.48, 623.43, 647.57, 4.71,
    300,              -- spawntimesecs (5 min)
    0.0,              -- wander_distance (Idle — does not wander)
    0,                -- currentwaypoint (always 0 per wiki)
    1, 0,             -- curhealth / curmana (always 1/0 per wiki)
    0,                -- MovementType (0 = Idle)
    0, 0, 0,          -- npcflag / unit_flags / dynamicflags (no overrides)
    NULL, NULL, 0,
    'mod-synival-paragon: Runic Archive gossip NPC'
);

-- ── Kadala spawn (Dalaran — near Violet Hold corridor) ─────
DELETE FROM `creature` WHERE `id1` = 99998;
INSERT INTO `creature` (
    `id1`, `id2`, `id3`,
    `map`, `zoneId`, `areaId`,
    `spawnMask`, `phaseMask`,
    `equipment_id`,
    `position_x`, `position_y`, `position_z`, `orientation`,
    `spawntimesecs`,
    `wander_distance`,
    `currentwaypoint`,
    `curhealth`, `curmana`,
    `MovementType`,
    `npcflag`, `unit_flags`, `dynamicflags`,
    `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`
) VALUES (
    99998, 0, 0,
    571, 0, 0,
    1, 1,
    0,
    5724.31, 761.10, 641.40, 3.14,
    300,
    0.0,
    0,
    1, 0,
    0,
    0, 0, 0,
    NULL, NULL, 0,
    'mod-synival-paragon: Kadala gambling merchant'
);

-- NOTE: The Butcher (entry 99997) has NO static creature row.
-- It is spawned dynamically at runtime via Map::SummonCreature()
-- inside AttemptPrestige() when a player reaches Prestige Rank 10.
-- Only creature_template is needed for a dynamically summoned NPC.


-- ============================================================
-- npc_text
-- ============================================================
-- Full column list per wiki schema.
--
-- Corrections vs. previous version:
--   • Previous INSERT only provided ID and text0_0, leaving
--     all other 80+ columns to implicit defaults — unreliable.
--   • All lang0-7 (TINYINT UNSIGNED, default 0),
--     Probability0-7 (FLOAT, default 0),
--     em0_0-5 through em7_0-5 (SMALLINT UNSIGNED, default 0),
--     and VerifiedBuild (SMALLINT SIGNED, default 1)
--     are now explicitly provided.
--   • text0_1 (female variant) mirrors text0_0.
--     text1_0 through text7_0 and their female variants are NULL
--     (only one text entry is needed per NPC for basic gossip).
--   • Probability0 = 1 so the engine always picks text0_0/1.
--     Probability1-7 = 0 (unused slots never selected).
-- ============================================================

-- ── Runic Archive gossip text (ID 99996) ───────────────────
DELETE FROM `npc_text` WHERE `ID` = 99996;
INSERT INTO `npc_text` (
    `ID`,
    `text0_0`, `text0_1`,
    `lang0`, `Probability0`,
    `em0_0`, `em0_1`, `em0_2`, `em0_3`, `em0_4`, `em0_5`,
    `text1_0`, `text1_1`,
    `lang1`, `Probability1`,
    `em1_0`, `em1_1`, `em1_2`, `em1_3`, `em1_4`, `em1_5`,
    `text2_0`, `text2_1`,
    `lang2`, `Probability2`,
    `em2_0`, `em2_1`, `em2_2`, `em2_3`, `em2_4`, `em2_5`,
    `text3_0`, `text3_1`,
    `lang3`, `Probability3`,
    `em3_0`, `em3_1`, `em3_2`, `em3_3`, `em3_4`, `em3_5`,
    `text4_0`, `text4_1`,
    `lang4`, `Probability4`,
    `em4_0`, `em4_1`, `em4_2`, `em4_3`, `em4_4`, `em4_5`,
    `text5_0`, `text5_1`,
    `lang5`, `Probability5`,
    `em5_0`, `em5_1`, `em5_2`, `em5_3`, `em5_4`, `em5_5`,
    `text6_0`, `text6_1`,
    `lang6`, `Probability6`,
    `em6_0`, `em6_1`, `em6_2`, `em6_3`, `em6_4`, `em6_5`,
    `text7_0`, `text7_1`,
    `lang7`, `Probability7`,
    `em7_0`, `em7_1`, `em7_2`, `em7_3`, `em7_4`, `em7_5`,
    `VerifiedBuild`
) VALUES (
    99996,
    -- Slot 0 — active text (male / female variants)
    'The Archive pulses with Paragon energy, $N. What knowledge do you seek?',
    'The Archive pulses with Paragon energy, $N. What knowledge do you seek?',
    0, 1,               -- lang0 = 0 (Universal); Probability0 = 1 (always shown)
    0, 0, 0, 0, 0, 0,   -- emotes 0-5 (none)
    -- Slots 1-7 — unused (NULL text, 0 probability)
    NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0,
    NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0,
    NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0,
    NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0,
    NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0,
    NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0,
    NULL, NULL, 0, 0, 0, 0, 0, 0, 0, 0,
    0                   -- VerifiedBuild
);

-- ── Kadala gossip text (ID 99998) ──────────────────────────
DELETE FROM `npc_text` WHERE `ID` = 99998;
INSERT INTO `npc_text` (
    `ID`,
    `text0_0`, `text0_1`,
    `lang0`, `Probability0`,
    `em0_0`, `em0_1`, `em0_2`, `em0_3`, `em0_4`, `em0_5`,
    `text1_0`, `text1_1`,
    `lang1`, `Probability1`,
    `em1_0`, `em1_1`, `em1_2`, `em1_3`, `em1_4`, `em1_5`,
    `text2_0`, `text2_1`,
    `lang2`, `Probability2`,
    `em2_0`, `em2_1`, `em2_2`, `em2_3`, `em2_4`, `em2_5`,
    `text3_0`, `text3_1`,
    `lang3`, `Probability3`,
    `em3_0`, `em3_1`, `em3_2`, `em3_3`, `em3_4`, `em3_5`,
    `text4_0`, `text4_1`,
    `lang4`, `Probability4`,
    `em4_0`, `em4_1`, `em4_2`, `em4_3`, `em4_4`, `em4_5`,
    `text5_0`, `text5_1`,
    `lang5`, `Probability5`,
    `em5_0`, `em5_1`, `em5_2`, `em5_3`, `em5_4`, `em5_5`,
    `text6_0`, `text6_1`,
    `lang6`, `Probability6`,
    `em6_0`, `em6_1`, `em6_2`, `em6_3`, `em6_4`, `em6_5`,
    `text7_0`, `text7_1`,
    `lang7`, `Probability7`,
    `em7_0`, `em7_1`, `em7_2`, `em7_3`, `em7_4`, `em7_5`,
    `VerifiedBuild`
) VALUES (
    99998,
    'Tempt fate, $N? Step forward... and let chance decide your destiny.',
    'Tempt fate, $N? Step forward... and let chance decide your destiny.',
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


-- ============================================================
-- item_template
-- ============================================================
-- Full column list per wiki schema.
--
-- Corrections vs. previous version:
--   • Renamed all spell columns: spell_id_1 → spellid_1,
--     spell_trigger_1 → spelltrigger_1, etc.
--   • `Flags` changed from INT to BIGINT SIGNED per wiki
--   • `BuyPrice` changed from INT to BIGINT SIGNED per wiki
--   • `SellPrice` is INT UNSIGNED per wiki
--   • `maxcount` is INT SIGNED per wiki (0 = unlimited)
--   • `stackable` is INT SIGNED per wiki (1 = not stackable)
--   • `WDBVerified` renamed to `VerifiedBuild` (SMALLINT SIGNED)
--   • Added all missing columns:
--       stat_type1-10 / stat_value1-10,
--       ScalingStatDistribution, ScalingStatValue,
--       dmg_min1/max1/type1, dmg_min2/max2/type2,
--       armor, all resistance columns,
--       delay, ammo_type, RangedModRange,
--       all 5 spell slot columns (spellid through spellcategorycooldown),
--       PageText, LanguageID, PageMaterial, startquest, lockid,
--       Material, sheath, RandomProperty, RandomSuffix, block,
--       itemset, MaxDurability, area, Map, BagFamily,
--       TotemCategory, socketColor/Content 1-3, socketBonus,
--       GemProperties, RequiredDisenchantSkill,
--       ArmorDamageModifier, duration, ItemLimitCategory,
--       HolidayId, DisenchantID, FoodType,
--       minMoneyLoot, maxMoneyLoot, flagsCustom
-- ============================================================

-- ── Runic Archive (item entry 99999) ───────────────────────
-- class = 15 (Miscellaneous), subclass = 0
-- Quality = 5 (Legendary — orange)
-- bonding = 1 (Binds when picked up)
-- InventoryType = 0 (Non-equippable — held/used item)
-- ScriptName = 'item_runic_archive' (wired to ItemScript in C++)
-- NOTE: If you convert to a pure NPC-based system (v2 source),
--       set ScriptName = '' and remove this item from the world.
DELETE FROM `item_template` WHERE `entry` = 99999;
INSERT INTO `item_template` (
    `entry`, `class`, `subclass`, `SoundOverrideSubclass`,
    `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`,
    `BuyCount`, `BuyPrice`, `SellPrice`,
    `InventoryType`, `AllowableClass`, `AllowableRace`,
    `ItemLevel`, `RequiredLevel`,
    `RequiredSkill`, `RequiredSkillRank`,
    `requiredspell`, `requiredhonorrank`,
    `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
    `maxcount`, `stackable`, `ContainerSlots`,
    `stat_type1`,  `stat_value1`,  `stat_type2`,  `stat_value2`,
    `stat_type3`,  `stat_value3`,  `stat_type4`,  `stat_value4`,
    `stat_type5`,  `stat_value5`,  `stat_type6`,  `stat_value6`,
    `stat_type7`,  `stat_value7`,  `stat_type8`,  `stat_value8`,
    `stat_type9`,  `stat_value9`,  `stat_type10`, `stat_value10`,
    `ScalingStatDistribution`, `ScalingStatValue`,
    `dmg_min1`, `dmg_max1`, `dmg_type1`,
    `dmg_min2`, `dmg_max2`, `dmg_type2`,
    `armor`,
    `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`,
    `delay`, `ammo_type`, `RangedModRange`,
    `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`,
    `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`, `spellcategory_2`, `spellcategorycooldown_2`,
    `spellid_3`, `spelltrigger_3`, `spellcharges_3`, `spellppmRate_3`, `spellcooldown_3`, `spellcategory_3`, `spellcategorycooldown_3`,
    `spellid_4`, `spelltrigger_4`, `spellcharges_4`, `spellppmRate_4`, `spellcooldown_4`, `spellcategory_4`, `spellcategorycooldown_4`,
    `spellid_5`, `spelltrigger_5`, `spellcharges_5`, `spellppmRate_5`, `spellcooldown_5`, `spellcategory_5`, `spellcategorycooldown_5`,
    `bonding`, `description`,
    `PageText`, `LanguageID`, `PageMaterial`,
    `startquest`, `lockid`, `Material`, `sheath`,
    `RandomProperty`, `RandomSuffix`, `block`,
    `itemset`, `MaxDurability`, `area`, `Map`,
    `BagFamily`, `TotemCategory`,
    `socketColor_1`, `socketContent_1`,
    `socketColor_2`, `socketContent_2`,
    `socketColor_3`, `socketContent_3`,
    `socketBonus`, `GemProperties`,
    `RequiredDisenchantSkill`, `ArmorDamageModifier`,
    `duration`, `ItemLimitCategory`, `HolidayId`,
    `ScriptName`, `DisenchantID`, `FoodType`,
    `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`,
    `VerifiedBuild`
) VALUES (
    99999, 15, 0, -1,
    'Runic Archive', 46170, 5, 0, 0,
    1, 0, 0,
    0, -1, -1,
    1, 80,
    0, 0,
    0, 0,
    0, 0, 0,
    1, 1, 0,
    -- stat_type/value 1-10 (all zero — no stats on this item)
    0, 0,  0, 0,  0, 0,  0, 0,  0, 0,
    0, 0,  0, 0,  0, 0,  0, 0,  0, 0,
    0, 0,
    -- damage (none)
    0, 0, 0,  0, 0, 0,
    0,  -- armor
    -- resistances (none)
    0, 0, 0, 0, 0, 0,
    1000, 0, 0.0,
    -- spell slots 1-5 (none)
    0, 0, 0, 0.0, -1, 0, -1,
    0, 0, 0, 0.0, -1, 0, -1,
    0, 0, 0, 0.0, -1, 0, -1,
    0, 0, 0, 0.0, -1, 0, -1,
    0, 0, 0, 0.0, -1, 0, -1,
    1, 'A tome bound in ancient runes. It thrums with Paragon energy.',
    0, 0, 0,
    0, 0, -1, 0,
    0, 0, 0,
    0, 0, 0, 0,
    0, 0,
    0, 0,  0, 0,  0, 0,
    0, 0,
    -1, 0.0,
    0, 0, 0,
    '', 0, 0,
    0, 0, 0,
    0
);

-- ── Mark of the Ascended (item entry 99300) ─────────────────
-- class = 0 (Consumable), subclass = 8 (Other)
-- Quality = 4 (Epic — purple)
-- bonding = 1 (Binds when picked up)
-- maxcount = 1 (cannot hold more than one at a time)
-- ScriptName = 'item_mark_of_ascension'
DELETE FROM `item_template` WHERE `entry` = 99300;
INSERT INTO `item_template` (
    `entry`, `class`, `subclass`, `SoundOverrideSubclass`,
    `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`,
    `BuyCount`, `BuyPrice`, `SellPrice`,
    `InventoryType`, `AllowableClass`, `AllowableRace`,
    `ItemLevel`, `RequiredLevel`,
    `RequiredSkill`, `RequiredSkillRank`,
    `requiredspell`, `requiredhonorrank`,
    `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
    `maxcount`, `stackable`, `ContainerSlots`,
    `stat_type1`,  `stat_value1`,  `stat_type2`,  `stat_value2`,
    `stat_type3`,  `stat_value3`,  `stat_type4`,  `stat_value4`,
    `stat_type5`,  `stat_value5`,  `stat_type6`,  `stat_value6`,
    `stat_type7`,  `stat_value7`,  `stat_type8`,  `stat_value8`,
    `stat_type9`,  `stat_value9`,  `stat_type10`, `stat_value10`,
    `ScalingStatDistribution`, `ScalingStatValue`,
    `dmg_min1`, `dmg_max1`, `dmg_type1`,
    `dmg_min2`, `dmg_max2`, `dmg_type2`,
    `armor`,
    `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`,
    `delay`, `ammo_type`, `RangedModRange`,
    `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`,
    `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`, `spellcategory_2`, `spellcategorycooldown_2`,
    `spellid_3`, `spelltrigger_3`, `spellcharges_3`, `spellppmRate_3`, `spellcooldown_3`, `spellcategory_3`, `spellcategorycooldown_3`,
    `spellid_4`, `spelltrigger_4`, `spellcharges_4`, `spellppmRate_4`, `spellcooldown_4`, `spellcategory_4`, `spellcategorycooldown_4`,
    `spellid_5`, `spelltrigger_5`, `spellcharges_5`, `spellppmRate_5`, `spellcooldown_5`, `spellcategory_5`, `spellcategorycooldown_5`,
    `bonding`, `description`,
    `PageText`, `LanguageID`, `PageMaterial`,
    `startquest`, `lockid`, `Material`, `sheath`,
    `RandomProperty`, `RandomSuffix`, `block`,
    `itemset`, `MaxDurability`, `area`, `Map`,
    `BagFamily`, `TotemCategory`,
    `socketColor_1`, `socketContent_1`,
    `socketColor_2`, `socketContent_2`,
    `socketColor_3`, `socketContent_3`,
    `socketBonus`, `GemProperties`,
    `RequiredDisenchantSkill`, `ArmorDamageModifier`,
    `duration`, `ItemLimitCategory`, `HolidayId`,
    `ScriptName`, `DisenchantID`, `FoodType`,
    `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`,
    `VerifiedBuild`
) VALUES (
    99300, 0, 8, -1,
    'Mark of the Ascended', 45978, 4, 0, 0,
    1, 500000, 250000,
    0, -1, -1,
    1, 80,
    0, 0,
    0, 0,
    0, 0, 0,
    1, 1, 0,
    0, 0,  0, 0,  0, 0,  0, 0,  0, 0,
    0, 0,  0, 0,  0, 0,  0, 0,  0, 0,
    0, 0,
    0, 0, 0,  0, 0, 0,
    0,
    0, 0, 0, 0, 0, 0,
    1000, 0, 0.0,
    -- spell slot 1: spelltrigger = 0 (on use), charges = 1 (consumed on use)
    -- spellid = 0 here; the C++ ItemScript fires the actual logic server-side
    0, 0, 1, 0.0, -1, 0, -1,
    0, 0, 0, 0.0, -1, 0, -1,
    0, 0, 0, 0.0, -1, 0, -1,
    0, 0, 0, 0.0, -1, 0, -1,
    0, 0, 0, 0.0, -1, 0, -1,
    1, 'Attunes all of your equipped gear to your Paragon power. Single use.',
    0, 0, 0,
    0, 0, -1, 0,
    0, 0, 0,
    0, 0, 0, 0,
    0, 0,
    0, 0,  0, 0,  0, 0,
    0, 0,
    -1, 0.0,
    0, 0, 0,
    'item_mark_of_ascension', 0, 0,
    0, 0, 0,
    0
);

-- ── Cache of Synival's Treasures (item entry 99200) ─────────
-- class = 15 (Miscellaneous), subclass = 0
-- Quality = 4 (Epic — purple)
-- bonding = 1 (Binds when picked up)
-- Awarded as a daily login reward via C++ — no ScriptName needed
DELETE FROM `item_template` WHERE `entry` = 99200;
INSERT INTO `item_template` (
    `entry`, `class`, `subclass`, `SoundOverrideSubclass`,
    `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`,
    `BuyCount`, `BuyPrice`, `SellPrice`,
    `InventoryType`, `AllowableClass`, `AllowableRace`,
    `ItemLevel`, `RequiredLevel`,
    `RequiredSkill`, `RequiredSkillRank`,
    `requiredspell`, `requiredhonorrank`,
    `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
    `maxcount`, `stackable`, `ContainerSlots`,
    `stat_type1`,  `stat_value1`,  `stat_type2`,  `stat_value2`,
    `stat_type3`,  `stat_value3`,  `stat_type4`,  `stat_value4`,
    `stat_type5`,  `stat_value5`,  `stat_type6`,  `stat_value6`,
    `stat_type7`,  `stat_value7`,  `stat_type8`,  `stat_value8`,
    `stat_type9`,  `stat_value9`,  `stat_type10`, `stat_value10`,
    `ScalingStatDistribution`, `ScalingStatValue`,
    `dmg_min1`, `dmg_max1`, `dmg_type1`,
    `dmg_min2`, `dmg_max2`, `dmg_type2`,
    `armor`,
    `holy_res`, `fire_res`, `nature_res`, `frost_res`, `shadow_res`, `arcane_res`,
    `delay`, `ammo_type`, `RangedModRange`,
    `spellid_1`, `spelltrigger_1`, `spellcharges_1`, `spellppmRate_1`, `spellcooldown_1`, `spellcategory_1`, `spellcategorycooldown_1`,
    `spellid_2`, `spelltrigger_2`, `spellcharges_2`, `spellppmRate_2`, `spellcooldown_2`, `spellcategory_2`, `spellcategorycooldown_2`,
    `spellid_3`, `spelltrigger_3`, `spellcharges_3`, `spellppmRate_3`, `spellcooldown_3`, `spellcategory_3`, `spellcategorycooldown_3`,
    `spellid_4`, `spelltrigger_4`, `spellcharges_4`, `spellppmRate_4`, `spellcooldown_4`, `spellcategory_4`, `spellcategorycooldown_4`,
    `spellid_5`, `spelltrigger_5`, `spellcharges_5`, `spellppmRate_5`, `spellcooldown_5`, `spellcategory_5`, `spellcategorycooldown_5`,
    `bonding`, `description`,
    `PageText`, `LanguageID`, `PageMaterial`,
    `startquest`, `lockid`, `Material`, `sheath`,
    `RandomProperty`, `RandomSuffix`, `block`,
    `itemset`, `MaxDurability`, `area`, `Map`,
    `BagFamily`, `TotemCategory`,
    `socketColor_1`, `socketContent_1`,
    `socketColor_2`, `socketContent_2`,
    `socketColor_3`, `socketContent_3`,
    `socketBonus`, `GemProperties`,
    `RequiredDisenchantSkill`, `ArmorDamageModifier`,
    `duration`, `ItemLimitCategory`, `HolidayId`,
    `ScriptName`, `DisenchantID`, `FoodType`,
    `minMoneyLoot`, `maxMoneyLoot`, `flagsCustom`,
    `VerifiedBuild`
) VALUES (
    99200, 15, 0, -1,
    'Cache of Synival''s Treasures', 29434, 4, 0, 0,
    1, 0, 0,
    0, -1, -1,
    1, 80,
    0, 0,
    0, 0,
    0, 0, 0,
    1, 1, 0,
    0, 0,  0, 0,  0, 0,  0, 0,  0, 0,
    0, 0,  0, 0,  0, 0,  0, 0,  0, 0,
    0, 0,
    0, 0, 0,  0, 0, 0,
    0,
    0, 0, 0, 0, 0, 0,
    1000, 0, 0.0,
    0, 0, 0, 0.0, -1, 0, -1,
    0, 0, 0, 0.0, -1, 0, -1,
    0, 0, 0, 0.0, -1, 0, -1,
    0, 0, 0, 0.0, -1, 0, -1,
    0, 0, 0, 0.0, -1, 0, -1,
    1, 'A daily reward containing crafting materials and gambling currency.',
    0, 0, 0,
    0, 0, -1, 0,
    0, 0, 0,
    0, 0, 0, 0,
    0, 0,
    0, 0,  0, 0,  0, 0,
    0, 0,
    -1, 0.0,
    0, 0, 0,
    '', 0, 0,
    0, 0, 0,
    0
);



-- ============================================================
-- creature_template_model
-- Required by modern AzerothCore builds
-- ============================================================

DELETE FROM `creature_template_model`
    WHERE `CreatureID` IN (99996, 99997, 99998);

INSERT INTO `creature_template_model`
    (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES
    (99996, 0, 1892,  1.0, 1.0, 0),  -- Mountaineer Kadrell (entry 1340) — armoured Ironforge dwarf
    (99997, 0, 31119, 2.0, 1.0, 0),  -- Lord Marrowgar model — enormous bone construct ICC boss
    (99998, 0, 30893, 1.0, 1.0, 0);  -- Lady Deathwhisper (entry 36855) — hooded ICC female raid boss



-- ============================================================
-- mod-synival-paragon | world database — BOARD SYSTEM
-- ============================================================
-- Run against your WORLD database.
-- Safe to run on an existing installation — all tables use
-- CREATE TABLE IF NOT EXISTS and node inserts use
-- INSERT IGNORE to avoid duplicate key errors on reload.
--
-- Entry ID ranges used:
--   Boards  : 1–41
--   Glyphs  : 1–6
--   Items   : 99100–99105  (glyph items)
-- ============================================================


-- ============================================================
-- TABLE DEFINITIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS `paragon_boards` (
    `board_id`              TINYINT  UNSIGNED NOT NULL,
    `name`                  VARCHAR(64)        NOT NULL DEFAULT '',
    `board_type`            TINYINT  UNSIGNED NOT NULL DEFAULT 0
                            COMMENT '0=Universal 1=Class 2=Spec',
    `required_class`        TINYINT  UNSIGNED NOT NULL DEFAULT 0
                            COMMENT '0=any; WoW class ID otherwise',
    `required_board`        TINYINT  UNSIGNED NOT NULL DEFAULT 0
                            COMMENT 'board_id that must have >= 1 node unlocked first (0=none)',
    `unlock_paragon_level`  INT      UNSIGNED NOT NULL DEFAULT 0,
    `unlock_prestige`       INT      UNSIGNED NOT NULL DEFAULT 0,
    `width`                 TINYINT  UNSIGNED NOT NULL DEFAULT 7,
    `height`                TINYINT  UNSIGNED NOT NULL DEFAULT 7,
    PRIMARY KEY (`board_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Synival Paragon Board — board registry';

CREATE TABLE IF NOT EXISTS `paragon_board_nodes` (
    `board_id`    TINYINT  UNSIGNED  NOT NULL,
    `node_id`     SMALLINT UNSIGNED  NOT NULL,
    `x`           TINYINT  UNSIGNED  NOT NULL DEFAULT 0,
    `y`           TINYINT  UNSIGNED  NOT NULL DEFAULT 0,
    `node_type`   TINYINT  UNSIGNED  NOT NULL DEFAULT 0
                  COMMENT '0=Normal 1=Magic 2=Rare 3=Socket 4=Start',
    `stat_type`   TINYINT  UNSIGNED  NOT NULL DEFAULT 0
                  COMMENT 'ParagonStatType enum',
    `stat_value`  FLOAT             NOT NULL DEFAULT 0,
    `name`        VARCHAR(64)        NOT NULL DEFAULT '',
    `description` VARCHAR(255)       NOT NULL DEFAULT '',
    PRIMARY KEY (`board_id`, `node_id`),
    KEY `idx_pbn_board` (`board_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Synival Paragon Board — node definitions';

CREATE TABLE IF NOT EXISTS `paragon_glyphs` (
    `glyph_id`         SMALLINT UNSIGNED NOT NULL,
    `name`             VARCHAR(64)        NOT NULL DEFAULT '',
    `radius`           TINYINT  UNSIGNED  NOT NULL DEFAULT 2,
    `rare_bonus_pct`   FLOAT              NOT NULL DEFAULT 50.0
                       COMMENT '% amplification applied to Rare nodes within radius',
    `bonus_stat_type`  TINYINT  UNSIGNED  NOT NULL DEFAULT 0
                       COMMENT 'Conditional bonus stat (ParagonStatType)',
    `bonus_stat_value` FLOAT              NOT NULL DEFAULT 0,
    `req_stat_type`    TINYINT  UNSIGNED  NOT NULL DEFAULT 0
                       COMMENT 'Stat type that must total req_stat_value in radius',
    `req_stat_value`   FLOAT              NOT NULL DEFAULT 0,
    `item_entry`       INT      UNSIGNED  NOT NULL DEFAULT 0,
    PRIMARY KEY (`glyph_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Synival Paragon Board — glyph definitions';


-- ============================================================
-- BOARD REGISTRY  (41 boards)
-- ============================================================
-- WoW class IDs: Warrior=1 Paladin=2 Hunter=3 Rogue=4 Priest=5
--                DeathKnight=6 Shaman=7 Mage=8 Warlock=9 Druid=11
-- ============================================================

DELETE FROM `paragon_boards`;
INSERT INTO `paragon_boards`
    (board_id, name, board_type, required_class, required_board, unlock_paragon_level, unlock_prestige, width, height)
VALUES
-- ── Universal ──────────────────────────────────────────────────────────────
(  1, 'The Awakening',                               0,  0,  0,   0, 0, 7, 7),
-- ── Class boards (unlock at Paragon 50) ────────────────────────────────────
(  2, 'Path of Iron',                                1,  1,  0,  50, 0, 7, 7),
(  3, 'Oath of the Light',                           1,  2,  0,  50, 0, 7, 7),
(  4, 'Hunter''s Mark',                              1,  3,  0,  50, 0, 7, 7),
(  5, 'Shadow''s Edge',                              1,  4,  0,  50, 0, 7, 7),
(  6, 'Veil of Divinity',                            1,  5,  0,  50, 0, 7, 7),
(  7, 'Grip of the Lich',                            1,  6,  0,  50, 0, 7, 7),
(  8, 'Eye of the Storm',                            1,  7,  0,  50, 0, 7, 7),
(  9, 'Arcane Confluence',                           1,  8,  0,  50, 0, 7, 7),
( 10, 'Pact of Ruin',                                1,  9,  0,  50, 0, 7, 7),
( 11, 'Cycle of Life',                               1, 11,  0,  50, 0, 7, 7),
-- ── Warrior spec boards (require board 2, unlock at Paragon 100) ───────────
( 12, 'Arms - Warmaster',                            2,  1,  2, 100, 0, 7, 7),
( 13, 'Fury - Bloodrage',                            2,  1,  2, 100, 0, 7, 7),
( 14, 'Protection - Bulwark',                        2,  1,  2, 100, 0, 7, 7),
-- ── Paladin spec boards (require board 3) ──────────────────────────────────
( 15, 'Holy - Radiance',                             2,  2,  3, 100, 0, 7, 7),
( 16, 'Protection - Aegis',                          2,  2,  3, 100, 0, 7, 7),
( 17, 'Retribution - Crusade',                       2,  2,  3, 100, 0, 7, 7),
-- ── Hunter spec boards (require board 4) ───────────────────────────────────
( 18, 'Beast Mastery - Pack Lord',                   2,  3,  4, 100, 0, 7, 7),
( 19, 'Marksmanship - Hawkeye',                      2,  3,  4, 100, 0, 7, 7),
( 20, 'Survival - Predator',                         2,  3,  4, 100, 0, 7, 7),
-- ── Rogue spec boards (require board 5) ────────────────────────────────────
( 21, 'Assassination - Venom',                       2,  4,  5, 100, 0, 7, 7),
( 22, 'Combat - Cutthroat',                          2,  4,  5, 100, 0, 7, 7),
( 23, 'Subtlety - Phantom',                          2,  4,  5, 100, 0, 7, 7),
-- ── Priest spec boards (require board 6) ───────────────────────────────────
( 24, 'Discipline - Bastion',                        2,  5,  6, 100, 0, 7, 7),
( 25, 'Holy - Serenity',                             2,  5,  6, 100, 0, 7, 7),
( 26, 'Shadow - Void',                               2,  5,  6, 100, 0, 7, 7),
-- ── Death Knight spec boards (require board 7) ─────────────────────────────
( 27, 'Blood - Crimson',                             2,  6,  7, 100, 0, 7, 7),
( 28, 'Frost - Glacial',                             2,  6,  7, 100, 0, 7, 7),
( 29, 'Unholy - Plague',                             2,  6,  7, 100, 0, 7, 7),
-- ── Shaman spec boards (require board 8) ───────────────────────────────────
( 30, 'Elemental - Maelstrom',                       2,  7,  8, 100, 0, 7, 7),
( 31, 'Enhancement - Earthbind',                     2,  7,  8, 100, 0, 7, 7),
( 32, 'Restoration - Tide',                          2,  7,  8, 100, 0, 7, 7),
-- ── Mage spec boards (require board 9) ─────────────────────────────────────
( 33, 'Arcane - Singularity',                        2,  8,  9, 100, 0, 7, 7),
( 34, 'Fire - Conflagration',                        2,  8,  9, 100, 0, 7, 7),
( 35, 'Frost - Glacialmind',                         2,  8,  9, 100, 0, 7, 7),
-- ── Warlock spec boards (require board 10) ─────────────────────────────────
( 36, 'Affliction - Torment',                        2,  9, 10, 100, 0, 7, 7),
( 37, 'Demonology - Pact',                           2,  9, 10, 100, 0, 7, 7),
( 38, 'Destruction - Chaos',                         2,  9, 10, 100, 0, 7, 7),
-- ── Druid spec boards (require board 11) ───────────────────────────────────
( 39, 'Balance - Celestial',                         2, 11, 11, 100, 0, 7, 7),
( 40, 'Feral - Primal',                              2, 11, 11, 100, 0, 7, 7),
( 41, 'Restoration - Verdant',                       2, 11, 11, 100, 0, 7, 7);


-- ============================================================
-- GLYPH DEFINITIONS
-- ============================================================
-- ParagonStatType: NONE=0 STR=1 AGL=2 STA=3 INT=4 SPI=5
--                 ARM=6 CRIT=7 HASTE=8 SP=9 AP=10
-- ============================================================

DELETE FROM `paragon_glyphs`;
INSERT INTO `paragon_glyphs`
    (glyph_id, name, radius, rare_bonus_pct, bonus_stat_type, bonus_stat_value, req_stat_type, req_stat_value, item_entry)
VALUES
(1, 'Glyph of the Tactician',    2, 50.0,  7,  10.0,  2,  25.0, 99100),
(2, 'Glyph of Reinforcement',    2, 40.0,  3, 200.0,  3,  30.0, 99101),
(3, 'Glyph of the Elementalist', 3, 35.0,  9, 150.0,  4,  20.0, 99102),
(4, 'Glyph of the Brawler',      2, 45.0, 10, 180.0,  1,  25.0, 99103),
(5, 'Glyph of the Phantom',      3, 30.0,  7,   8.0,  2,  20.0, 99104),
(6, 'Glyph of Ironhide',         1, 60.0,  6, 250.0,  3,  35.0, 99105);


-- ============================================================
-- GLYPH ITEM TEMPLATES  (entries 99100-99105)
-- Uses minimal explicit-column INSERTs — only the columns this
-- module actually needs are specified. MySQL fills in defaults
-- for everything else, making this immune to schema variation
-- between AzerothCore versions.
-- ============================================================

DELETE FROM `item_template` WHERE `entry` IN (99100, 99101, 99102, 99103, 99104, 99105);

-- Glyph of the Tactician
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `SoundOverrideSubclass`,
     `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`,
     `BuyCount`, `BuyPrice`, `SellPrice`,
     `InventoryType`, `AllowableClass`, `AllowableRace`,
     `ItemLevel`, `RequiredLevel`,
     `RequiredSkill`, `RequiredSkillRank`,
     `requiredspell`, `requiredhonorrank`,
     `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
     `maxcount`, `stackable`, `ContainerSlots`,
     `delay`, `bonding`, `description`,
     `Material`, `VerifiedBuild`)
VALUES
    (99100, 15, 0, -1,
     'Glyph of the Tactician', 45978, 4, 0, 0,
     1, 0, 0,
     0, -1, -1,
     1, 80,
     0, 0,
     0, 0,
     0, 0, 0,
     1, 1, 0,
     1000, 1, 'Socket into a Paragon Board Socket node to amplify nearby Rare nodes.',
     -1, 0);

-- Glyph of Reinforcement
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `SoundOverrideSubclass`,
     `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`,
     `BuyCount`, `BuyPrice`, `SellPrice`,
     `InventoryType`, `AllowableClass`, `AllowableRace`,
     `ItemLevel`, `RequiredLevel`,
     `RequiredSkill`, `RequiredSkillRank`,
     `requiredspell`, `requiredhonorrank`,
     `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
     `maxcount`, `stackable`, `ContainerSlots`,
     `delay`, `bonding`, `description`,
     `Material`, `VerifiedBuild`)
VALUES
    (99101, 15, 0, -1,
     'Glyph of Reinforcement', 45978, 4, 0, 0,
     1, 0, 0,
     0, -1, -1,
     1, 80,
     0, 0,
     0, 0,
     0, 0, 0,
     1, 1, 0,
     1000, 1, 'Socket into a Paragon Board Socket node to amplify nearby Rare nodes.',
     -1, 0);

-- Glyph of the Elementalist
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `SoundOverrideSubclass`,
     `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`,
     `BuyCount`, `BuyPrice`, `SellPrice`,
     `InventoryType`, `AllowableClass`, `AllowableRace`,
     `ItemLevel`, `RequiredLevel`,
     `RequiredSkill`, `RequiredSkillRank`,
     `requiredspell`, `requiredhonorrank`,
     `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
     `maxcount`, `stackable`, `ContainerSlots`,
     `delay`, `bonding`, `description`,
     `Material`, `VerifiedBuild`)
VALUES
    (99102, 15, 0, -1,
     'Glyph of the Elementalist', 45978, 4, 0, 0,
     1, 0, 0,
     0, -1, -1,
     1, 80,
     0, 0,
     0, 0,
     0, 0, 0,
     1, 1, 0,
     1000, 1, 'Socket into a Paragon Board Socket node to amplify nearby Rare nodes.',
     -1, 0);

-- Glyph of the Brawler
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `SoundOverrideSubclass`,
     `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`,
     `BuyCount`, `BuyPrice`, `SellPrice`,
     `InventoryType`, `AllowableClass`, `AllowableRace`,
     `ItemLevel`, `RequiredLevel`,
     `RequiredSkill`, `RequiredSkillRank`,
     `requiredspell`, `requiredhonorrank`,
     `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
     `maxcount`, `stackable`, `ContainerSlots`,
     `delay`, `bonding`, `description`,
     `Material`, `VerifiedBuild`)
VALUES
    (99103, 15, 0, -1,
     'Glyph of the Brawler', 45978, 4, 0, 0,
     1, 0, 0,
     0, -1, -1,
     1, 80,
     0, 0,
     0, 0,
     0, 0, 0,
     1, 1, 0,
     1000, 1, 'Socket into a Paragon Board Socket node to amplify nearby Rare nodes.',
     -1, 0);

-- Glyph of the Phantom
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `SoundOverrideSubclass`,
     `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`,
     `BuyCount`, `BuyPrice`, `SellPrice`,
     `InventoryType`, `AllowableClass`, `AllowableRace`,
     `ItemLevel`, `RequiredLevel`,
     `RequiredSkill`, `RequiredSkillRank`,
     `requiredspell`, `requiredhonorrank`,
     `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
     `maxcount`, `stackable`, `ContainerSlots`,
     `delay`, `bonding`, `description`,
     `Material`, `VerifiedBuild`)
VALUES
    (99104, 15, 0, -1,
     'Glyph of the Phantom', 45978, 4, 0, 0,
     1, 0, 0,
     0, -1, -1,
     1, 80,
     0, 0,
     0, 0,
     0, 0, 0,
     1, 1, 0,
     1000, 1, 'Socket into a Paragon Board Socket node to amplify nearby Rare nodes.',
     -1, 0);

-- Glyph of Ironhide
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `SoundOverrideSubclass`,
     `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`,
     `BuyCount`, `BuyPrice`, `SellPrice`,
     `InventoryType`, `AllowableClass`, `AllowableRace`,
     `ItemLevel`, `RequiredLevel`,
     `RequiredSkill`, `RequiredSkillRank`,
     `requiredspell`, `requiredhonorrank`,
     `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
     `maxcount`, `stackable`, `ContainerSlots`,
     `delay`, `bonding`, `description`,
     `Material`, `VerifiedBuild`)
VALUES
    (99105, 15, 0, -1,
     'Glyph of Ironhide', 45978, 4, 0, 0,
     1, 0, 0,
     0, -1, -1,
     1, 80,
     0, 0,
     0, 0,
     0, 0, 0,
     1, 1, 0,
     1000, 1, 'Socket into a Paragon Board Socket node to amplify nearby Rare nodes.',
     -1, 0);

-- ============================================================
-- PARAGON SHARD ITEM (entry 99400)
-- Currency item dropped by elites (10% chance, handled in C++).
-- Also purchasable from Kadala in bundles of 100 for 500g
-- (24hr per-player cooldown enforced in C++ gossip handler).
-- class=15 Miscellaneous, Quality=3 (Uncommon — blue coins)
-- ============================================================

DELETE FROM `item_template` WHERE `entry` = 99400;
INSERT INTO `item_template`
    (`entry`, `class`, `subclass`, `SoundOverrideSubclass`,
     `name`, `displayid`, `Quality`, `Flags`, `FlagsExtra`,
     `BuyCount`, `BuyPrice`, `SellPrice`,
     `InventoryType`, `AllowableClass`, `AllowableRace`,
     `ItemLevel`, `RequiredLevel`,
     `RequiredSkill`, `RequiredSkillRank`,
     `requiredspell`, `requiredhonorrank`,
     `RequiredCityRank`, `RequiredReputationFaction`, `RequiredReputationRank`,
     `maxcount`, `stackable`, `ContainerSlots`,
     `delay`, `bonding`, `description`,
     `Material`, `VerifiedBuild`)
VALUES
    (99400, 15, 0, -1,
     'Paragon Shard', 45978, 3, 0, 0,
     1, 0, 0,
     0, -1, -1,
     1, 1,
     0, 0,
     0, 0,
     0, 0, 0,
     0, 1000, 0,
     1000, 4, 'A crystallised fragment of Paragon energy. Used to purchase Legendary class equipment.',
     -1, 0);
-- ============================================================
-- PARAGON BOARD NODE DEFINITIONS
-- ============================================================
-- All 41 boards share the same 7x7 positional layout.
-- Only stat_type and stat_value differ per board.
--
-- POSITION MAP (node_id : x, y, type)
--  1 : 3,3  START  (always free, always adjacent)
--  2 : 3,1  MAGIC   3 : 2,2  MAGIC   4 : 3,2  SOCKET
--  5 : 4,2  MAGIC   6 : 2,3  MAGIC   7 : 4,3  MAGIC
--  8 : 2,4  MAGIC   9 : 3,4  SOCKET  10: 4,4  MAGIC
-- 11 : 3,5  MAGIC
-- 12 : 1,1  NORMAL 13: 2,1  NORMAL  14: 4,1  NORMAL
-- 15 : 5,1  NORMAL 16: 1,2  NORMAL  17: 5,2  NORMAL
-- 18 : 1,3  NORMAL 19: 5,3  NORMAL  20: 1,4  NORMAL
-- 21 : 5,4  NORMAL 22: 1,5  NORMAL  23: 2,5  NORMAL
-- 24 : 4,5  NORMAL 25: 5,5  NORMAL
-- 26 : 2,0  RARE   27: 4,0  RARE    28: 0,2  RARE
-- 29 : 6,2  RARE   30: 0,4  RARE    31: 6,4  RARE
-- 32 : 2,6  RARE   33: 4,6  RARE
--
-- node_type: 0=Normal 1=Magic 2=Rare 3=Socket 4=Start
-- stat_type: 0=None 1=STR 2=AGL 3=STA 4=INT 5=SPI
--            6=ARM 7=CRIT% 8=HASTE% 9=SP 10=AP
-- Normal/Magic nodes: flat values  (STR/AGL/STA/INT/SPI/ARM/AP/SP)
-- Rare nodes:         pct values   (any stat_type, applied as %)
-- Socket nodes:       stat_type=0, stat_value=0 (glyph drives bonus)
--
-- Value tiers:
--   Universal (board 1): Normal 25-40, Magic 60-80, Rare 0.5-1.5%
--   Class     (2-11):    Normal 35-55, Magic 80-110, Rare 1.0-2.0%
--   Spec      (12-41):   Normal 45-70, Magic 100-140, Rare 1.5-2.5%
-- ============================================================

DELETE FROM `paragon_board_nodes`;

-- ============================================================
-- BOARD 1 — The Awakening (Universal)
-- Theme: balanced across all primary stats
-- ============================================================
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
( 1, 1,3,3,4, 0,  0.0,'The First Step',      'Your journey as a Paragon begins here.'),
( 1, 2,3,1,1, 3, 80.0,'Iron Constitution',   '+80 Stamina'),
( 1, 3,2,2,1, 1, 60.0,'Titan Strength',      '+60 Strength'),
( 1, 4,3,2,3, 0,  0.0,'Glyph Socket',        'Socket a Glyph to amplify nearby Rare nodes.'),
( 1, 5,4,2,1, 2, 60.0,'Swift Reflexes',      '+60 Agility'),
( 1, 6,2,3,1, 4, 60.0,'Arcane Mind',         '+60 Intellect'),
( 1, 7,4,3,1, 5, 60.0,'Wellspring of Spirit','+60 Spirit'),
( 1, 8,2,4,1, 1, 60.0,'Unyielding Power',    '+60 Strength'),
( 1, 9,3,4,3, 0,  0.0,'Glyph Socket',        'Socket a Glyph to amplify nearby Rare nodes.'),
( 1,10,4,4,1, 2, 60.0,'Quickened Step',      '+60 Agility'),
( 1,11,3,5,1, 3, 80.0,'Enduring Resolve',    '+80 Stamina'),
( 1,12,1,1,0, 3, 40.0,'Resilience',          '+40 Stamina'),
( 1,13,2,1,0, 1, 30.0,'Brawn',               '+30 Strength'),
( 1,14,4,1,0, 2, 30.0,'Agility',             '+30 Agility'),
( 1,15,5,1,0, 5, 25.0,'Clarity',             '+25 Spirit'),
( 1,16,1,2,0, 1, 30.0,'Might',               '+30 Strength'),
( 1,17,5,2,0, 2, 30.0,'Deftness',            '+30 Agility'),
( 1,18,1,3,0, 3, 40.0,'Vitality',            '+40 Stamina'),
( 1,19,5,3,0, 5, 25.0,'Serenity',            '+25 Spirit'),
( 1,20,1,4,0, 1, 30.0,'Raw Power',           '+30 Strength'),
( 1,21,5,4,0, 2, 30.0,'Nimbleness',          '+30 Agility'),
( 1,22,1,5,0, 3, 40.0,'Fortitude',           '+40 Stamina'),
( 1,23,2,5,0, 4, 25.0,'Insight',             '+25 Intellect'),
( 1,24,4,5,0, 5, 25.0,'Harmony',             '+25 Spirit'),
( 1,25,5,5,0, 3, 40.0,'Endurance',           '+40 Stamina'),
( 1,26,2,0,2, 3,  1.5,'Titanic Endurance',   '+1.5% Stamina'),
( 1,27,4,0,2, 2,  1.0,'Ethereal Grace',      '+1.0% Agility'),
( 1,28,0,2,2,10,  1.5,'Primal Fury',         '+1.5% Attack Power'),
( 1,29,6,2,2, 9,  1.5,'Mystic Surge',        '+1.5% Spell Power'),
( 1,30,0,4,2, 7,  0.5,'Lethal Edge',         '+0.5% Critical Strike'),
( 1,31,6,4,2, 8,  0.5,'Rapid Flow',          '+0.5% Haste'),
( 1,32,2,6,2, 1,  1.0,'Ancient Might',       '+1.0% Strength'),
( 1,33,4,6,2, 5,  1.0,'Soulful Surge',       '+1.0% Spirit');

-- ============================================================
-- BOARD 2 — Path of Iron (Warrior Class)
-- Theme: Strength, Stamina, Attack Power
-- ============================================================
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
( 2, 1,3,3,4, 0,  0.0,'The Iron Path',        'Forged in battle, tempered in blood.'),
( 2, 2,3,1,1, 3, 90.0,'War-Hardened Body',    '+90 Stamina'),
( 2, 3,2,2,1, 1,100.0,'Crushing Blow',        '+100 Strength'),
( 2, 4,3,2,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 2, 5,4,2,1, 1,100.0,'Titan Arms',           '+100 Strength'),
( 2, 6,2,3,1, 3, 90.0,'Ironclad Flesh',       '+90 Stamina'),
( 2, 7,4,3,1, 1,100.0,'Warlord Presence',     '+100 Strength'),
( 2, 8,2,4,1, 3, 90.0,'Battle Endurance',     '+90 Stamina'),
( 2, 9,3,4,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 2,10,4,4,1,10, 80.0,'Savage Drive',         '+80 Attack Power'),
( 2,11,3,5,1, 1,100.0,'Juggernaut Will',      '+100 Strength'),
( 2,12,1,1,0, 1, 45.0,'Soldier Strength',     '+45 Strength'),
( 2,13,2,1,0, 3, 45.0,'Soldier Stamina',      '+45 Stamina'),
( 2,14,4,1,0, 1, 45.0,'War Grip',             '+45 Strength'),
( 2,15,5,1,0, 3, 45.0,'Combat Reserves',      '+45 Stamina'),
( 2,16,1,2,0, 1, 45.0,'Iron Sinew',           '+45 Strength'),
( 2,17,5,2,0, 3, 45.0,'Battle-Worn',          '+45 Stamina'),
( 2,18,1,3,0, 1, 45.0,'Warrior Pride',        '+45 Strength'),
( 2,19,5,3,0, 3, 45.0,'Unbroken',             '+45 Stamina'),
( 2,20,1,4,0, 1, 45.0,'Blade Mastery',        '+45 Strength'),
( 2,21,5,4,0, 3, 45.0,'Last Stand',           '+45 Stamina'),
( 2,22,1,5,0, 1, 45.0,'Unstoppable',          '+45 Strength'),
( 2,23,2,5,0, 3, 45.0,'Defiant',              '+45 Stamina'),
( 2,24,4,5,0, 1, 45.0,'War Veteran',          '+45 Strength'),
( 2,25,5,5,0, 3, 45.0,'Iron Resolve',         '+45 Stamina'),
( 2,26,2,0,2,10,  2.0,'Ferocity',             '+2.0% Attack Power'),
( 2,27,4,0,2, 6,  1.5,'Steel Skin',           '+1.5% Armor'),
( 2,28,0,2,2, 1,  1.5,'Mountain Strength',    '+1.5% Strength'),
( 2,29,6,2,2, 3,  2.0,'Behemoth Stamina',     '+2.0% Stamina'),
( 2,30,0,4,2, 7,  0.5,'Warrior Precision',    '+0.5% Critical Strike'),
( 2,31,6,4,2,10,  2.0,'Raging Might',         '+2.0% Attack Power'),
( 2,32,2,6,2, 1,  1.5,'Giant Strength',       '+1.5% Strength'),
( 2,33,4,6,2, 6,  1.5,'Fortress Hide',        '+1.5% Armor');

-- ============================================================
-- BOARD 3 — Oath of the Light (Paladin Class)
-- Theme: Strength, Stamina, Intellect, Spell Power
-- ============================================================
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
( 3, 1,3,3,4, 0,  0.0,'The Sacred Oath',      'Blessed by the Light.'),
( 3, 2,3,1,1, 3, 90.0,'Holy Endurance',       '+90 Stamina'),
( 3, 3,2,2,1, 1, 90.0,'Blessed Strength',     '+90 Strength'),
( 3, 4,3,2,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 3, 5,4,2,1, 4, 85.0,'Divine Intellect',     '+85 Intellect'),
( 3, 6,2,3,1, 9, 80.0,'Holy Radiance',        '+80 Spell Power'),
( 3, 7,4,3,1, 1, 90.0,'Zealot Might',         '+90 Strength'),
( 3, 8,2,4,1, 3, 90.0,'Seal of Life',         '+90 Stamina'),
( 3, 9,3,4,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 3,10,4,4,1, 4, 85.0,'Arcane Devotion',      '+85 Intellect'),
( 3,11,3,5,1, 1, 90.0,'Crusader Resolve',     '+90 Strength'),
( 3,12,1,1,0, 1, 45.0,'Holy Strength',        '+45 Strength'),
( 3,13,2,1,0, 3, 40.0,'Sacred Vitality',      '+40 Stamina'),
( 3,14,4,1,0, 4, 35.0,'Blessed Mind',         '+35 Intellect'),
( 3,15,5,1,0, 5, 30.0,'Pious Heart',          '+30 Spirit'),
( 3,16,1,2,0, 1, 45.0,'Bulwark of Faith',     '+45 Strength'),
( 3,17,5,2,0, 4, 35.0,'Enlightened',          '+35 Intellect'),
( 3,18,1,3,0, 3, 40.0,'Paladin Endurance',    '+40 Stamina'),
( 3,19,5,3,0, 5, 30.0,'Inner Light',          '+30 Spirit'),
( 3,20,1,4,0, 1, 45.0,'Divine Purpose',       '+45 Strength'),
( 3,21,5,4,0, 4, 35.0,'Studious Mind',        '+35 Intellect'),
( 3,22,1,5,0, 3, 40.0,'Righteous Body',       '+40 Stamina'),
( 3,23,2,5,0, 5, 30.0,'Merciful Soul',        '+30 Spirit'),
( 3,24,4,5,0, 1, 45.0,'Templar Will',         '+45 Strength'),
( 3,25,5,5,0, 3, 40.0,'Devoted Flesh',        '+40 Stamina'),
( 3,26,2,0,2, 3,  1.5,'Shield of the Faithful','+1.5% Stamina'),
( 3,27,4,0,2, 9,  1.5,'Holy Fire',            '+1.5% Spell Power'),
( 3,28,0,2,2, 1,  1.5,'Champion Strength',    '+1.5% Strength'),
( 3,29,6,2,2, 4,  1.0,'Arcane Grace',         '+1.0% Intellect'),
( 3,30,0,4,2, 7,  0.5,'Divine Strike',        '+0.5% Critical Strike'),
( 3,31,6,4,2, 9,  1.5,'Light Made Manifest',  '+1.5% Spell Power'),
( 3,32,2,6,2, 1,  1.5,'Blessed Arms',         '+1.5% Strength'),
( 3,33,4,6,2, 3,  1.5,'Holy Vigor',           '+1.5% Stamina');

-- ============================================================
-- BOARD 4 — Hunter's Mark (Hunter Class)
-- Theme: Agility, Attack Power, Critical Strike
-- ============================================================
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
( 4, 1,3,3,4, 0,  0.0,"The Hunter's Path",    'Track, stalk, and strike.'),
( 4, 2,3,1,1, 2, 95.0,'Deadly Grace',         '+95 Agility'),
( 4, 3,2,2,1,10, 85.0,'Pack Leader',          '+85 Attack Power'),
( 4, 4,3,2,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 4, 5,4,2,1, 2, 95.0,'Feline Reflexes',      '+95 Agility'),
( 4, 6,2,3,1, 3, 80.0,'Survival Instinct',    '+80 Stamina'),
( 4, 7,4,3,1,10, 85.0,'Predator Mark',        '+85 Attack Power'),
( 4, 8,2,4,1, 2, 95.0,'Shadow Step',          '+95 Agility'),
( 4, 9,3,4,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 4,10,4,4,1, 3, 80.0,'Wilderness Endurance', '+80 Stamina'),
( 4,11,3,5,1, 2, 95.0,'Eagle Eyes',           '+95 Agility'),
( 4,12,1,1,0, 2, 45.0,'Swift Footing',        '+45 Agility'),
( 4,13,2,1,0,10, 40.0,'Aimed Blow',           '+40 Attack Power'),
( 4,14,4,1,0, 2, 45.0,'Feral Speed',          '+45 Agility'),
( 4,15,5,1,0, 3, 35.0,'Tenacity',             '+35 Stamina'),
( 4,16,1,2,0, 2, 45.0,'Tracker Agility',      '+45 Agility'),
( 4,17,5,2,0,10, 40.0,'Marked Shot',          '+40 Attack Power'),
( 4,18,1,3,0, 2, 45.0,'Panther Stance',       '+45 Agility'),
( 4,19,5,3,0, 3, 35.0,'Scout Reserves',       '+35 Stamina'),
( 4,20,1,4,0, 2, 45.0,'Predator Stance',      '+45 Agility'),
( 4,21,5,4,0,10, 40.0,'Piercing Volley',      '+40 Attack Power'),
( 4,22,1,5,0, 2, 45.0,'Wind Runner',          '+45 Agility'),
( 4,23,2,5,0, 3, 35.0,'Ranger Grit',          '+35 Stamina'),
( 4,24,4,5,0, 2, 45.0,'Serpent Speed',        '+45 Agility'),
( 4,25,5,5,0,10, 40.0,'Kill Shot Drive',      '+40 Attack Power'),
( 4,26,2,0,2, 2,  2.0,'Apex Predator',        '+2.0% Agility'),
( 4,27,4,0,2,10,  2.0,'Deadeye',              '+2.0% Attack Power'),
( 4,28,0,2,2, 7,  0.8,'Lethal Precision',     '+0.8% Critical Strike'),
( 4,29,6,2,2, 2,  2.0,'Lynx Grace',           '+2.0% Agility'),
( 4,30,0,4,2, 8,  0.5,'Swift Draw',           '+0.5% Haste'),
( 4,31,6,4,2,10,  2.0,'Apex Strike',          '+2.0% Attack Power'),
( 4,32,2,6,2, 7,  0.8,'Critical Instinct',    '+0.8% Critical Strike'),
( 4,33,4,6,2, 3,  1.5,'Stalker Endurance',    '+1.5% Stamina');

-- ============================================================
-- BOARD 5 — Shadow's Edge (Rogue Class)
-- Theme: Agility, Attack Power, Critical Strike
-- ============================================================
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
( 5, 1,3,3,4, 0,  0.0,'The Shadow Path',      'Strike from the dark. Vanish without trace.'),
( 5, 2,3,1,1, 2, 95.0,'Ghost Step',           '+95 Agility'),
( 5, 3,2,2,1,10, 85.0,'Poison Mastery',       '+85 Attack Power'),
( 5, 4,3,2,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 5, 5,4,2,1, 2, 95.0,'Shadowstrike',         '+95 Agility'),
( 5, 6,2,3,1,10, 85.0,'Blade Expertise',      '+85 Attack Power'),
( 5, 7,4,3,1, 2, 95.0,'Viper Reflexes',       '+95 Agility'),
( 5, 8,2,4,1,10, 85.0,'Killing Edge',         '+85 Attack Power'),
( 5, 9,3,4,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 5,10,4,4,1, 2, 95.0,'Phantom Agility',      '+95 Agility'),
( 5,11,3,5,1, 3, 75.0,'Assassin Stamina',     '+75 Stamina'),
( 5,12,1,1,0, 2, 45.0,'Blade Dance',          '+45 Agility'),
( 5,13,2,1,0,10, 40.0,'Venom Strike',         '+40 Attack Power'),
( 5,14,4,1,0, 2, 45.0,'Smoke Form',           '+45 Agility'),
( 5,15,5,1,0, 3, 35.0,'Shadow Vitality',      '+35 Stamina'),
( 5,16,1,2,0, 2, 45.0,'Silent Footwork',      '+45 Agility'),
( 5,17,5,2,0,10, 40.0,'Cut Throat',           '+40 Attack Power'),
( 5,18,1,3,0, 2, 45.0,'Evasion',              '+45 Agility'),
( 5,19,5,3,0, 3, 35.0,'Dark Reserves',        '+35 Stamina'),
( 5,20,1,4,0, 2, 45.0,'Death Mark',           '+45 Agility'),
( 5,21,5,4,0,10, 40.0,'Serrated Blade',       '+40 Attack Power'),
( 5,22,1,5,0, 2, 45.0,'Shadow Walk',          '+45 Agility'),
( 5,23,2,5,0, 3, 35.0,'Rogue Endurance',      '+35 Stamina'),
( 5,24,4,5,0, 2, 45.0,'Elusive Movement',     '+45 Agility'),
( 5,25,5,5,0,10, 40.0,'Finisher Power',       '+40 Attack Power'),
( 5,26,2,0,2, 2,  2.0,'Phantom Form',         '+2.0% Agility'),
( 5,27,4,0,2, 7,  0.8,'Assassin Precision',   '+0.8% Critical Strike'),
( 5,28,0,2,2,10,  2.0,'Backstab Fury',        '+2.0% Attack Power'),
( 5,29,6,2,2, 2,  2.0,'Shadow Agility',       '+2.0% Agility'),
( 5,30,0,4,2, 8,  0.5,'Blade Tempo',          '+0.5% Haste'),
( 5,31,6,4,2, 7,  0.8,'Lethal Opportunist',   '+0.8% Critical Strike'),
( 5,32,2,6,2,10,  2.0,'Killing Blow',         '+2.0% Attack Power'),
( 5,33,4,6,2, 2,  2.0,'Night Runner',         '+2.0% Agility');

-- ============================================================
-- BOARD 6 — Veil of Divinity (Priest Class)
-- Theme: Intellect, Spirit, Spell Power
-- ============================================================
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
( 6, 1,3,3,4, 0,  0.0,'The Sacred Veil',      'The Light speaks through you.'),
( 6, 2,3,1,1, 4, 95.0,'Brilliant Mind',       '+95 Intellect'),
( 6, 3,2,2,1, 9, 85.0,'Holy Channel',         '+85 Spell Power'),
( 6, 4,3,2,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 6, 5,4,2,1, 5, 90.0,'Flowing Spirit',       '+90 Spirit'),
( 6, 6,2,3,1, 4, 95.0,'Enlightened Soul',     '+95 Intellect'),
( 6, 7,4,3,1, 9, 85.0,'Divine Surge',         '+85 Spell Power'),
( 6, 8,2,4,1, 5, 90.0,'Renewal',              '+90 Spirit'),
( 6, 9,3,4,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 6,10,4,4,1, 4, 95.0,'Veil Scholar',         '+95 Intellect'),
( 6,11,3,5,1, 3, 80.0,'Holy Endurance',       '+80 Stamina'),
( 6,12,1,1,0, 4, 45.0,'Clear Thought',        '+45 Intellect'),
( 6,13,2,1,0, 5, 40.0,'Soft Breath',          '+40 Spirit'),
( 6,14,4,1,0, 4, 45.0,'Arcane Acuity',        '+45 Intellect'),
( 6,15,5,1,0, 3, 35.0,'Priest Vitality',      '+35 Stamina'),
( 6,16,1,2,0, 5, 40.0,'Mending Touch',        '+40 Spirit'),
( 6,17,5,2,0, 4, 45.0,'Focused Faith',        '+45 Intellect'),
( 6,18,1,3,0, 4, 45.0,'Keen Mind',            '+45 Intellect'),
( 6,19,5,3,0, 5, 40.0,'Channeled Calm',       '+40 Spirit'),
( 6,20,1,4,0, 5, 40.0,'Restful Aura',         '+40 Spirit'),
( 6,21,5,4,0, 4, 45.0,'Luminous Thought',     '+45 Intellect'),
( 6,22,1,5,0, 4, 45.0,'Prophet Mind',         '+45 Intellect'),
( 6,23,2,5,0, 3, 35.0,'Devotion',             '+35 Stamina'),
( 6,24,4,5,0, 5, 40.0,'Grace',                '+40 Spirit'),
( 6,25,5,5,0, 4, 45.0,'Seraphic Wisdom',      '+45 Intellect'),
( 6,26,2,0,2, 5,  1.5,'Wellspring of Light',  '+1.5% Spirit'),
( 6,27,4,0,2, 9,  1.5,'Holy Nova',            '+1.5% Spell Power'),
( 6,28,0,2,2, 4,  1.5,'Font of Knowledge',    '+1.5% Intellect'),
( 6,29,6,2,2, 5,  1.5,'River of Renewal',     '+1.5% Spirit'),
( 6,30,0,4,2, 8,  0.5,'Sermon Tempo',         '+0.5% Haste'),
( 6,31,6,4,2, 9,  1.5,'Radiant Burst',        '+1.5% Spell Power'),
( 6,32,2,6,2, 7,  0.5,'Divine Strike',        '+0.5% Critical Strike'),
( 6,33,4,6,2, 4,  1.5,'Omniscient',           '+1.5% Intellect');

-- ============================================================
-- BOARD 7 — Grip of the Lich (Death Knight Class)
-- Theme: Strength, Stamina, Armor
-- ============================================================
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
( 7, 1,3,3,4, 0,  0.0,'The Death Gate',       'Risen from death to conquer life.'),
( 7, 2,3,1,1, 1,100.0,'Runic Strength',       '+100 Strength'),
( 7, 3,2,2,1, 3, 95.0,'Undead Endurance',     '+95 Stamina'),
( 7, 4,3,2,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 7, 5,4,2,1, 6, 85.0,'Bone Plating',         '+85 Armor'),
( 7, 6,2,3,1, 1,100.0,'Lich King Might',      '+100 Strength'),
( 7, 7,4,3,1, 3, 95.0,'Deathbound',           '+95 Stamina'),
( 7, 8,2,4,1, 6, 85.0,'Necrotic Armor',       '+85 Armor'),
( 7, 9,3,4,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 7,10,4,4,1, 1,100.0,'Rune-Carved Muscle',   '+100 Strength'),
( 7,11,3,5,1, 3, 95.0,'Plague Resistance',    '+95 Stamina'),
( 7,12,1,1,0, 1, 50.0,'Death Grip',           '+50 Strength'),
( 7,13,2,1,0, 3, 45.0,'Corpse Vitality',      '+45 Stamina'),
( 7,14,4,1,0, 1, 50.0,'Runic Sinew',          '+50 Strength'),
( 7,15,5,1,0, 6, 40.0,'Dark Armor',           '+40 Armor'),
( 7,16,1,2,0, 3, 45.0,'Iron Marrow',          '+45 Stamina'),
( 7,17,5,2,0, 1, 50.0,'Frost Strength',       '+50 Strength'),
( 7,18,1,3,0, 1, 50.0,'Plague Strength',      '+50 Strength'),
( 7,19,5,3,0, 3, 45.0,'Blood Pool',           '+45 Stamina'),
( 7,20,1,4,0, 6, 40.0,'Bone Shield',          '+40 Armor'),
( 7,21,5,4,0, 1, 50.0,'Deathchill Power',     '+50 Strength'),
( 7,22,1,5,0, 3, 45.0,'Unholy Endurance',     '+45 Stamina'),
( 7,23,2,5,0, 1, 50.0,'Scourge Might',        '+50 Strength'),
( 7,24,4,5,0, 6, 40.0,'Plated Death',         '+40 Armor'),
( 7,25,5,5,0, 3, 45.0,'Rune Endurance',       '+45 Stamina'),
( 7,26,2,0,2, 1,  1.5,'Lich Might',           '+1.5% Strength'),
( 7,27,4,0,2, 3,  2.0,'Death Shroud',         '+2.0% Stamina'),
( 7,28,0,2,2, 6,  1.5,'Saronite Plating',     '+1.5% Armor'),
( 7,29,6,2,2, 1,  1.5,'Runic Colossus',       '+1.5% Strength'),
( 7,30,0,4,2,10,  2.0,'Death Strike Force',   '+2.0% Attack Power'),
( 7,31,6,4,2, 6,  1.5,'Fortress of Bone',     '+1.5% Armor'),
( 7,32,2,6,2, 3,  2.0,'Endless Undeath',      '+2.0% Stamina'),
( 7,33,4,6,2, 7,  0.5,'Deathblow Precision',  '+0.5% Critical Strike');

-- ============================================================
-- BOARD 8 — Eye of the Storm (Shaman Class)
-- Theme: Intellect, Spell Power, Agility (hybrid)
-- ============================================================
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
( 8, 1,3,3,4, 0,  0.0,'The Earthen Path',     'Wind, fire, earth, water — all obey.'),
( 8, 2,3,1,1, 4, 90.0,'Elemental Mind',       '+90 Intellect'),
( 8, 3,2,2,1, 9, 85.0,'Stormcaller Power',    '+85 Spell Power'),
( 8, 4,3,2,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 8, 5,4,2,1, 2, 85.0,'Earthen Agility',      '+85 Agility'),
( 8, 6,2,3,1, 4, 90.0,'Spirit Walker',        '+90 Intellect'),
( 8, 7,4,3,1, 9, 85.0,'Lightning Weave',      '+85 Spell Power'),
( 8, 8,2,4,1, 5, 80.0,'Ancestor Breath',      '+80 Spirit'),
( 8, 9,3,4,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 8,10,4,4,1, 4, 90.0,'Totem Mastery',        '+90 Intellect'),
( 8,11,3,5,1, 3, 80.0,'Primal Endurance',     '+80 Stamina'),
( 8,12,1,1,0, 4, 42.0,'Storm Clarity',        '+42 Intellect'),
( 8,13,2,1,0, 5, 38.0,'Calm Waters',          '+38 Spirit'),
( 8,14,4,1,0, 2, 40.0,'Swift Current',        '+40 Agility'),
( 8,15,5,1,0, 3, 35.0,'Tide Endurance',       '+35 Stamina'),
( 8,16,1,2,0, 4, 42.0,'Thunder Mind',         '+42 Intellect'),
( 8,17,5,2,0, 9, 38.0,'Spark Weave',          '+38 Spell Power'),
( 8,18,1,3,0, 2, 40.0,'Wind Feet',            '+40 Agility'),
( 8,19,5,3,0, 5, 38.0,'Soul Link',            '+38 Spirit'),
( 8,20,1,4,0, 4, 42.0,'Focused Totems',       '+42 Intellect'),
( 8,21,5,4,0, 2, 40.0,'River Step',           '+40 Agility'),
( 8,22,1,5,0, 5, 38.0,'Peaceful Flow',        '+38 Spirit'),
( 8,23,2,5,0, 3, 35.0,'Shaman Grit',          '+35 Stamina'),
( 8,24,4,5,0, 4, 42.0,'Ancient Wisdom',       '+42 Intellect'),
( 8,25,5,5,0, 9, 38.0,'Tempest Weave',        '+38 Spell Power'),
( 8,26,2,0,2, 9,  1.5,'Maelstrom Power',      '+1.5% Spell Power'),
( 8,27,4,0,2, 8,  0.8,'Storm Tempo',          '+0.8% Haste'),
( 8,28,0,2,2, 4,  1.5,'Primal Intellect',     '+1.5% Intellect'),
( 8,29,6,2,2, 2,  1.5,'Wind Walk',            '+1.5% Agility'),
( 8,30,0,4,2, 8,  0.8,'Tide of Battle',       '+0.8% Haste'),
( 8,31,6,4,2, 9,  1.5,'Crackling Chain',      '+1.5% Spell Power'),
( 8,32,2,6,2, 5,  1.5,'Ancestor Soul',        '+1.5% Spirit'),
( 8,33,4,6,2, 7,  0.5,'Thunder Crit',         '+0.5% Critical Strike');

-- ============================================================
-- BOARD 9 — Arcane Confluence (Mage Class)
-- Theme: Intellect, Spell Power, Haste
-- ============================================================
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
( 9, 1,3,3,4, 0,  0.0,'The Arcane Nexus',     'Reality bends to your will.'),
( 9, 2,3,1,1, 4,100.0,'Arcane Intellect',     '+100 Intellect'),
( 9, 3,2,2,1, 9, 90.0,'Spellfire Surge',      '+90 Spell Power'),
( 9, 4,3,2,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 9, 5,4,2,1, 4,100.0,'Mana Convergence',     '+100 Intellect'),
( 9, 6,2,3,1, 9, 90.0,'Prismatic Weave',      '+90 Spell Power'),
( 9, 7,4,3,1, 5, 80.0,'Mana Spring',          '+80 Spirit'),
( 9, 8,2,4,1, 4,100.0,'Spellcraft Master',    '+100 Intellect'),
( 9, 9,3,4,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
( 9,10,4,4,1, 9, 90.0,'Arcane Cascade',       '+90 Spell Power'),
( 9,11,3,5,1, 4,100.0,'Confluence of Power',  '+100 Intellect'),
( 9,12,1,1,0, 4, 48.0,'Studious',             '+48 Intellect'),
( 9,13,2,1,0, 5, 38.0,'Mana Attunement',      '+38 Spirit'),
( 9,14,4,1,0, 4, 48.0,'Focused Casting',      '+48 Intellect'),
( 9,15,5,1,0, 3, 30.0,'Mage Endurance',       '+30 Stamina'),
( 9,16,1,2,0, 9, 42.0,'Spell Focus',          '+42 Spell Power'),
( 9,17,5,2,0, 4, 48.0,'Brilliant Scholar',    '+48 Intellect'),
( 9,18,1,3,0, 4, 48.0,'Arcane Mastery',       '+48 Intellect'),
( 9,19,5,3,0, 5, 38.0,'Mana River',           '+38 Spirit'),
( 9,20,1,4,0, 9, 42.0,'Spell Surge',          '+42 Spell Power'),
( 9,21,5,4,0, 4, 48.0,'Quick Study',          '+48 Intellect'),
( 9,22,1,5,0, 4, 48.0,'Infinite Reserve',     '+48 Intellect'),
( 9,23,2,5,0, 3, 30.0,'Conjured Vitality',    '+30 Stamina'),
( 9,24,4,5,0, 5, 38.0,'Ley Calm',             '+38 Spirit'),
( 9,25,5,5,0, 9, 42.0,'Channeled Force',      '+42 Spell Power'),
( 9,26,2,0,2, 4,  1.5,'Infinite Intellect',   '+1.5% Intellect'),
( 9,27,4,0,2, 9,  1.5,'Arcane Surge',         '+1.5% Spell Power'),
( 9,28,0,2,2, 8,  0.8,'Blink Speed',          '+0.8% Haste'),
( 9,29,6,2,2, 4,  1.5,'Nexus Scholar',        '+1.5% Intellect'),
( 9,30,0,4,2, 8,  0.8,'Rapid Spellwork',      '+0.8% Haste'),
( 9,31,6,4,2, 9,  1.5,'Prismatic Explosion',  '+1.5% Spell Power'),
( 9,32,2,6,2, 7,  0.5,'Arcane Crit',          '+0.5% Critical Strike'),
( 9,33,4,6,2, 5,  1.5,'Mana Reservoir',       '+1.5% Spirit');

-- ============================================================
-- BOARD 10 — Pact of Ruin (Warlock Class)
-- Theme: Intellect, Spell Power, Stamina
-- ============================================================
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(10, 1,3,3,4, 0,  0.0,'The Dark Pact',        'Power through suffering — yours and theirs.'),
(10, 2,3,1,1, 4, 95.0,'Fel Intellect',        '+95 Intellect'),
(10, 3,2,2,1, 9, 88.0,'Corruption Power',     '+88 Spell Power'),
(10, 4,3,2,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
(10, 5,4,2,1, 3, 90.0,'Dark Pact Stamina',    '+90 Stamina'),
(10, 6,2,3,1, 4, 95.0,'Shadow Intellect',     '+95 Intellect'),
(10, 7,4,3,1, 9, 88.0,'Ruination',            '+88 Spell Power'),
(10, 8,2,4,1, 3, 90.0,'Demonic Endurance',    '+90 Stamina'),
(10, 9,3,4,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
(10,10,4,4,1, 4, 95.0,'Chaos Mastery',        '+95 Intellect'),
(10,11,3,5,1, 9, 88.0,'Havoc Wave',           '+88 Spell Power'),
(10,12,1,1,0, 4, 45.0,'Malice Mind',          '+45 Intellect'),
(10,13,2,1,0, 3, 42.0,'Life Tap Reserves',    '+42 Stamina'),
(10,14,4,1,0, 4, 45.0,'Demonic Focus',        '+45 Intellect'),
(10,15,5,1,0, 5, 32.0,'Shadow Calm',          '+32 Spirit'),
(10,16,1,2,0, 3, 42.0,'Soul Armor',           '+42 Stamina'),
(10,17,5,2,0, 4, 45.0,'Warlock Cunning',      '+45 Intellect'),
(10,18,1,3,0, 4, 45.0,'Infernal Mind',        '+45 Intellect'),
(10,19,5,3,0, 3, 42.0,'Pact Endurance',       '+42 Stamina'),
(10,20,1,4,0, 9, 40.0,'Bane Surge',           '+40 Spell Power'),
(10,21,5,4,0, 4, 45.0,'Affliction Acuity',    '+45 Intellect'),
(10,22,1,5,0, 3, 42.0,'Dark Body',            '+42 Stamina'),
(10,23,2,5,0, 4, 45.0,'Void Scholar',         '+45 Intellect'),
(10,24,4,5,0, 9, 40.0,'Chaotic Weave',        '+40 Spell Power'),
(10,25,5,5,0, 3, 42.0,'Demonic Vigor',        '+42 Stamina'),
(10,26,2,0,2, 9,  1.5,'Fel Surge',            '+1.5% Spell Power'),
(10,27,4,0,2, 3,  2.0,'Soul Sacrifice',       '+2.0% Stamina'),
(10,28,0,2,2, 4,  1.5,'Infinite Malice',      '+1.5% Intellect'),
(10,29,6,2,2, 9,  1.5,'Void Torrent',         '+1.5% Spell Power'),
(10,30,0,4,2, 8,  0.5,'Dark Tempo',           '+0.5% Haste'),
(10,31,6,4,2, 3,  2.0,'Demonic Body',         '+2.0% Stamina'),
(10,32,2,6,2, 7,  0.5,'Chaos Precision',      '+0.5% Critical Strike'),
(10,33,4,6,2, 4,  1.5,'Ruinous Insight',      '+1.5% Intellect');

-- ============================================================
-- BOARD 11 — Cycle of Life (Druid Class)
-- Theme: Stamina, Agility, Intellect (hybrid nature)
-- ============================================================
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(11, 1,3,3,4, 0,  0.0,'The Grove Heart',      'Nature pulses through every form.'),
(11, 2,3,1,1, 3, 90.0,'Ancient Bark',         '+90 Stamina'),
(11, 3,2,2,1, 2, 88.0,'Feral Grace',          '+88 Agility'),
(11, 4,3,2,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
(11, 5,4,2,1, 4, 85.0,'Moonfire Mind',        '+85 Intellect'),
(11, 6,2,3,1, 3, 90.0,'Earthen Bark',         '+90 Stamina'),
(11, 7,4,3,1, 2, 88.0,'Cat Swiftness',        '+88 Agility'),
(11, 8,2,4,1, 5, 80.0,'Naturalist Soul',      '+80 Spirit'),
(11, 9,3,4,3, 0,  0.0,'Glyph Socket',         'Socket a Glyph.'),
(11,10,4,4,1, 4, 85.0,'Stellar Acuity',       '+85 Intellect'),
(11,11,3,5,1, 3, 90.0,'Overgrowth',           '+90 Stamina'),
(11,12,1,1,0, 3, 42.0,'Bark Armor',           '+42 Stamina'),
(11,13,2,1,0, 2, 40.0,'Feline Speed',         '+40 Agility'),
(11,14,4,1,0, 4, 38.0,'Grove Mind',           '+38 Intellect'),
(11,15,5,1,0, 5, 35.0,'Nature Calm',          '+35 Spirit'),
(11,16,1,2,0, 2, 40.0,'Stalker Agility',      '+40 Agility'),
(11,17,5,2,0, 3, 42.0,'Treeform Endurance',   '+42 Stamina'),
(11,18,1,3,0, 4, 38.0,'Lunar Mind',           '+38 Intellect'),
(11,19,5,3,0, 5, 35.0,'Forest Soul',          '+35 Spirit'),
(11,20,1,4,0, 3, 42.0,'Bear Form Stamina',    '+42 Stamina'),
(11,21,5,4,0, 2, 40.0,'Prowl Agility',        '+40 Agility'),
(11,22,1,5,0, 5, 35.0,'Root Calm',            '+35 Spirit'),
(11,23,2,5,0, 4, 38.0,'Dream Insight',        '+38 Intellect'),
(11,24,4,5,0, 3, 42.0,'Ancient Growth',       '+42 Stamina'),
(11,25,5,5,0, 2, 40.0,'Wind Paws',            '+40 Agility'),
(11,26,2,0,2, 3,  1.5,'Ancient Vitality',     '+1.5% Stamina'),
(11,27,4,0,2, 2,  1.5,'Feral Surge',          '+1.5% Agility'),
(11,28,0,2,2, 5,  1.5,'Verdant Spirit',       '+1.5% Spirit'),
(11,29,6,2,2, 4,  1.5,'Celestial Mind',       '+1.5% Intellect'),
(11,30,0,4,2, 7,  0.5,'Predator Instinct',    '+0.5% Critical Strike'),
(11,31,6,4,2, 9,  1.5,'Moonfire Surge',       '+1.5% Spell Power'),
(11,32,2,6,2, 2,  1.5,'Wild Agility',         '+1.5% Agility'),
(11,33,4,6,2, 3,  1.5,'Grove Endurance',      '+1.5% Stamina');
-- ============================================================
-- SPEC BOARD NODES CONTINUED (board 17 completion → board 41)
-- ============================================================

-- Board 17 — Retribution: Crusade (continued from cut-off)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(17,29,6,2,2, 1,  2.5,'Titan Retribution',     '+2.5% Strength'),
(17,30,0,4,2,10,  2.5,'Storm of Judgement',    '+2.5% Attack Power'),
(17,31,6,4,2, 7,  1.2,'Blessed Precision',     '+1.2% Critical Strike'),
(17,32,2,6,2, 1,  2.5,'Holy Warrior Might',    '+2.5% Strength'),
(17,33,4,6,2, 3,  2.0,'Retribution Endurance', '+2.0% Stamina');

-- ============================================================
-- HUNTER SPEC BOARDS
-- ============================================================

-- Board 18 — Beast Mastery: Pack Lord  (AP%, Stamina%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(18, 1,3,3,4, 0,  0.0,'The Pack Lord',         'Your beast is an extension of your will.'),
(18, 2,3,1,1, 2,130.0,'Feral Cunning',         '+130 Agility'),
(18, 3,2,2,1,10,125.0,'Beast Synergy',         '+125 Attack Power'),
(18, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(18, 5,4,2,1, 3,115.0,'Pack Endurance',        '+115 Stamina'),
(18, 6,2,3,1, 2,130.0,'Alpha Agility',         '+130 Agility'),
(18, 7,4,3,1,10,125.0,'Kill Command Power',    '+125 Attack Power'),
(18, 8,2,4,1, 3,115.0,'Bestial Wrath Body',    '+115 Stamina'),
(18, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(18,10,4,4,1, 2,130.0,'Spirit Bond',           '+130 Agility'),
(18,11,3,5,1,10,125.0,'Serpent Swiftness',     '+125 Attack Power'),
(18,12,1,1,0, 2, 60.0,'Pack Agility',          '+60 Agility'),
(18,13,2,1,0,10, 55.0,'Claw Strike',           '+55 Attack Power'),
(18,14,4,1,0, 2, 60.0,'Alpha Speed',           '+60 Agility'),
(18,15,5,1,0, 3, 52.0,'Beast Stamina',         '+52 Stamina'),
(18,16,1,2,0,10, 55.0,'Pet Synergy',           '+55 Attack Power'),
(18,17,5,2,0, 2, 60.0,'Feral Agility',         '+60 Agility'),
(18,18,1,3,0, 2, 60.0,'Wild Hunt',             '+60 Agility'),
(18,19,5,3,0, 3, 52.0,'Primal Reserves',       '+52 Stamina'),
(18,20,1,4,0,10, 55.0,'Pack Fury',             '+55 Attack Power'),
(18,21,5,4,0, 2, 60.0,'Bestial Speed',         '+60 Agility'),
(18,22,1,5,0, 3, 52.0,'Hunter Endurance',      '+52 Stamina'),
(18,23,2,5,0, 2, 60.0,'Apex Agility',          '+60 Agility'),
(18,24,4,5,0,10, 55.0,'Dire Beast Power',      '+55 Attack Power'),
(18,25,5,5,0, 2, 60.0,'Frenzy Agility',        '+60 Agility'),
(18,26,2,0,2,10,  2.5,'Pack Ferocity',         '+2.5% Attack Power'),
(18,27,4,0,2, 3,  2.0,'Survival Reserves',     '+2.0% Stamina'),
(18,28,0,2,2, 2,  2.0,'Alpha Swiftness',       '+2.0% Agility'),
(18,29,6,2,2,10,  2.5,'Beast Mastery Power',   '+2.5% Attack Power'),
(18,30,0,4,2, 8,  0.8,'Pack Sprint',           '+0.8% Haste'),
(18,31,6,4,2, 2,  2.0,'Feral Surge',           '+2.0% Agility'),
(18,32,2,6,2, 7,  0.8,'Pack Hunter Crit',      '+0.8% Critical Strike'),
(18,33,4,6,2, 3,  2.0,'Bestial Endurance',     '+2.0% Stamina');

-- Board 19 — Marksmanship: Hawkeye  (Crit%, Agility%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(19, 1,3,3,4, 0,  0.0,'The Hawkeye',           'One arrow. One kill. Perfect form.'),
(19, 2,3,1,1, 2,135.0,'Hawk Agility',          '+135 Agility'),
(19, 3,2,2,1,10,120.0,'Aimed Shot Power',      '+120 Attack Power'),
(19, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(19, 5,4,2,1, 2,135.0,'Eagle Eye Agility',     '+135 Agility'),
(19, 6,2,3,1,10,120.0,'Chimera Shot Power',    '+120 Attack Power'),
(19, 7,4,3,1, 2,135.0,'Steady Shot Agility',   '+135 Agility'),
(19, 8,2,4,1, 3,110.0,'Hawk Endurance',        '+110 Stamina'),
(19, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(19,10,4,4,1,10,120.0,'Kill Shot Power',       '+120 Attack Power'),
(19,11,3,5,1, 2,135.0,'Sniper Agility',        '+135 Agility'),
(19,12,1,1,0, 2, 62.0,'Marksman Agility',      '+62 Agility'),
(19,13,2,1,0,10, 55.0,'Aimed Blow',            '+55 Attack Power'),
(19,14,4,1,0, 2, 62.0,'Hawkeye Agility',       '+62 Agility'),
(19,15,5,1,0, 3, 50.0,'Scout Endurance',       '+50 Stamina'),
(19,16,1,2,0,10, 55.0,'Volley Power',          '+55 Attack Power'),
(19,17,5,2,0, 2, 62.0,'Piercing Shot Agility', '+62 Agility'),
(19,18,1,3,0, 2, 62.0,'Surefoot Agility',      '+62 Agility'),
(19,19,5,3,0, 3, 50.0,'Ranger Endurance',      '+50 Stamina'),
(19,20,1,4,0,10, 55.0,'Scatter Shot Power',    '+55 Attack Power'),
(19,21,5,4,0, 2, 62.0,'Wind Runner Agility',   '+62 Agility'),
(19,22,1,5,0, 3, 50.0,'Marksman Endurance',    '+50 Stamina'),
(19,23,2,5,0, 2, 62.0,'Deadeye Agility',       '+62 Agility'),
(19,24,4,5,0,10, 55.0,'Rapid Fire Power',      '+55 Attack Power'),
(19,25,5,5,0, 2, 62.0,'True Shot Agility',     '+62 Agility'),
(19,26,2,0,2, 7,  1.5,'Deadeye Precision',     '+1.5% Critical Strike'),
(19,27,4,0,2, 2,  2.5,'Eagle Agility',         '+2.5% Agility'),
(19,28,0,2,2, 7,  1.5,'Sniper Crit',           '+1.5% Critical Strike'),
(19,29,6,2,2, 2,  2.5,'Hawkeye Agility Surge', '+2.5% Agility'),
(19,30,0,4,2,10,  2.5,'Aimed Barrage',         '+2.5% Attack Power'),
(19,31,6,4,2, 7,  1.5,'Killshot Precision',    '+1.5% Critical Strike'),
(19,32,2,6,2, 2,  2.5,'Wind Dancer',           '+2.5% Agility'),
(19,33,4,6,2, 3,  2.0,'Sniper Endurance',      '+2.0% Stamina');

-- Board 20 — Survival: Predator  (Agility%, Haste%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(20, 1,3,3,4, 0,  0.0,'The Predator',          'Trap, flank, and overwhelm.'),
(20, 2,3,1,1, 2,130.0,'Predator Agility',      '+130 Agility'),
(20, 3,2,2,1,10,118.0,'Explosive Shot Power',  '+118 Attack Power'),
(20, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(20, 5,4,2,1, 2,130.0,'Trap Master Agility',   '+130 Agility'),
(20, 6,2,3,1,10,118.0,'Black Arrow Power',     '+118 Attack Power'),
(20, 7,4,3,1, 2,130.0,'Counterattack Agility', '+130 Agility'),
(20, 8,2,4,1, 3,112.0,'Survival Endurance',    '+112 Stamina'),
(20, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(20,10,4,4,1,10,118.0,'Lock and Load Power',   '+118 Attack Power'),
(20,11,3,5,1, 2,130.0,'Survivalist Agility',   '+130 Agility'),
(20,12,1,1,0, 2, 60.0,'Tracker Agility',       '+60 Agility'),
(20,13,2,1,0, 3, 52.0,'Wilderness Stamina',    '+52 Stamina'),
(20,14,4,1,0, 2, 60.0,'Ambush Agility',        '+60 Agility'),
(20,15,5,1,0,10, 52.0,'Flanking Strike',       '+52 Attack Power'),
(20,16,1,2,0,10, 52.0,'Trap Expertise',        '+52 Attack Power'),
(20,17,5,2,0, 2, 60.0,'Ghost Step Agility',    '+60 Agility'),
(20,18,1,3,0, 2, 60.0,'Wyvern Sting Agility',  '+60 Agility'),
(20,19,5,3,0, 3, 52.0,'Field Reserves',        '+52 Stamina'),
(20,20,1,4,0, 2, 60.0,'Disengage Agility',     '+60 Agility'),
(20,21,5,4,0,10, 52.0,'Explosive Power',       '+52 Attack Power'),
(20,22,1,5,0, 3, 52.0,'Scout Endurance',       '+52 Stamina'),
(20,23,2,5,0, 2, 60.0,'Camouflage Agility',    '+60 Agility'),
(20,24,4,5,0,10, 52.0,'Flanker Power',         '+52 Attack Power'),
(20,25,5,5,0, 2, 60.0,'Apex Predator Agility', '+60 Agility'),
(20,26,2,0,2, 2,  2.5,'Predator Surge',        '+2.5% Agility'),
(20,27,4,0,2, 8,  1.2,'Hunter Tempo',          '+1.2% Haste'),
(20,28,0,2,2, 2,  2.5,'Ghost Runner',          '+2.5% Agility'),
(20,29,6,2,2, 8,  1.2,'Serpent Sting Tempo',   '+1.2% Haste'),
(20,30,0,4,2,10,  2.5,'Survival Fury',         '+2.5% Attack Power'),
(20,31,6,4,2, 2,  2.5,'Wind Stalker',          '+2.5% Agility'),
(20,32,2,6,2, 7,  0.8,'Ambush Crit',           '+0.8% Critical Strike'),
(20,33,4,6,2, 3,  2.0,'Wilderness Endurance',  '+2.0% Stamina');

-- ============================================================
-- ROGUE SPEC BOARDS
-- ============================================================

-- Board 21 — Assassination: Venom  (Crit%, Agility%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(21, 1,3,3,4, 0,  0.0,'The Venom Path',        'Poison courses through your blade and soul.'),
(21, 2,3,1,1, 2,135.0,'Viper Agility',         '+135 Agility'),
(21, 3,2,2,1,10,122.0,'Mutilate Power',        '+122 Attack Power'),
(21, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(21, 5,4,2,1, 2,135.0,'Rupture Agility',       '+135 Agility'),
(21, 6,2,3,1,10,122.0,'Envenom Power',         '+122 Attack Power'),
(21, 7,4,3,1, 2,135.0,'Cold Blood Agility',    '+135 Agility'),
(21, 8,2,4,1, 3,110.0,'Poisoner Endurance',    '+110 Stamina'),
(21, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(21,10,4,4,1,10,122.0,'Overkill Power',        '+122 Attack Power'),
(21,11,3,5,1, 2,135.0,'Slice Dice Agility',    '+135 Agility'),
(21,12,1,1,0, 2, 62.0,'Venom Agility',         '+62 Agility'),
(21,13,2,1,0,10, 56.0,'Deadly Poison AP',      '+56 Attack Power'),
(21,14,4,1,0, 2, 62.0,'Fan of Knives Agility', '+62 Agility'),
(21,15,5,1,0, 3, 50.0,'Shadow Stamina',        '+50 Stamina'),
(21,16,1,2,0,10, 56.0,'Ambush Power',          '+56 Attack Power'),
(21,17,5,2,0, 2, 62.0,'Shadowstep Agility',    '+62 Agility'),
(21,18,1,3,0, 2, 62.0,'Vendetta Agility',      '+62 Agility'),
(21,19,5,3,0, 3, 50.0,'Rogue Endurance',       '+50 Stamina'),
(21,20,1,4,0,10, 56.0,'Garrote Power',         '+56 Attack Power'),
(21,21,5,4,0, 2, 62.0,'Preparation Agility',   '+62 Agility'),
(21,22,1,5,0, 3, 50.0,'Assassin Endurance',    '+50 Stamina'),
(21,23,2,5,0, 2, 62.0,'Cloak Agility',         '+62 Agility'),
(21,24,4,5,0,10, 56.0,'Backstab Power',        '+56 Attack Power'),
(21,25,5,5,0, 2, 62.0,'Killing Spree Agility', '+62 Agility'),
(21,26,2,0,2, 7,  1.5,'Lethal Venom Crit',     '+1.5% Critical Strike'),
(21,27,4,0,2, 2,  2.5,'Viper Swiftness',       '+2.5% Agility'),
(21,28,0,2,2, 7,  1.5,'Rupture Precision',     '+1.5% Critical Strike'),
(21,29,6,2,2, 2,  2.5,'Phantom Agility',       '+2.5% Agility'),
(21,30,0,4,2,10,  2.5,'Mutilate Surge',        '+2.5% Attack Power'),
(21,31,6,4,2, 7,  1.5,'Envenom Crit',          '+1.5% Critical Strike'),
(21,32,2,6,2, 2,  2.5,'Shadow Speed',          '+2.5% Agility'),
(21,33,4,6,2, 3,  2.0,'Venom Endurance',       '+2.0% Stamina');

-- Board 22 — Combat: Cutthroat  (AP%, Haste%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(22, 1,3,3,4, 0,  0.0,'The Cutthroat',         'Fast blades, no honour, all results.'),
(22, 2,3,1,1,10,130.0,'Sinister Strike Power', '+130 Attack Power'),
(22, 3,2,2,1, 2,128.0,'Combat Agility',        '+128 Agility'),
(22, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(22, 5,4,2,1,10,130.0,'Revealing Strike Power','+130 Attack Power'),
(22, 6,2,3,1, 2,128.0,'Blade Flurry Agility',  '+128 Agility'),
(22, 7,4,3,1,10,130.0,'Adrenaline Rush Power', '+130 Attack Power'),
(22, 8,2,4,1, 3,112.0,'Combat Endurance',      '+112 Stamina'),
(22, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(22,10,4,4,1, 2,128.0,'Riposte Agility',       '+128 Agility'),
(22,11,3,5,1,10,130.0,'Killing Spree Power',   '+130 Attack Power'),
(22,12,1,1,0,10, 58.0,'Dual Wield Fury',       '+58 Attack Power'),
(22,13,2,1,0, 2, 58.0,'Combat Speed',          '+58 Agility'),
(22,14,4,1,0,10, 58.0,'Off-Hand Mastery',      '+58 Attack Power'),
(22,15,5,1,0, 3, 52.0,'Cutthroat Endurance',   '+52 Stamina'),
(22,16,1,2,0, 2, 58.0,'Fleet Footwork',        '+58 Agility'),
(22,17,5,2,0,10, 58.0,'Aggression Power',      '+58 Attack Power'),
(22,18,1,3,0,10, 58.0,'Savage Combat Power',   '+58 Attack Power'),
(22,19,5,3,0, 3, 52.0,'Battle Reserves',       '+52 Stamina'),
(22,20,1,4,0, 2, 58.0,'Deflection Agility',    '+58 Agility'),
(22,21,5,4,0,10, 58.0,'Hack and Slash Power',  '+58 Attack Power'),
(22,22,1,5,0, 3, 52.0,'Combat Grit',           '+52 Stamina'),
(22,23,2,5,0, 2, 58.0,'Lightning Reflexes',    '+58 Agility'),
(22,24,4,5,0,10, 58.0,'Eviscerate Power',      '+58 Attack Power'),
(22,25,5,5,0, 2, 58.0,'Fast Hands Agility',    '+58 Agility'),
(22,26,2,0,2, 8,  1.2,'Combat Tempo',          '+1.2% Haste'),
(22,27,4,0,2,10,  2.5,'Blade Storm Fury',      '+2.5% Attack Power'),
(22,28,0,2,2, 8,  1.2,'Adrenaline Speed',      '+1.2% Haste'),
(22,29,6,2,2, 2,  2.5,'Acrobatic Speed',       '+2.5% Agility'),
(22,30,0,4,2,10,  2.5,'Relentless Strikes',    '+2.5% Attack Power'),
(22,31,6,4,2, 8,  1.2,'Blade Flurry Tempo',    '+1.2% Haste'),
(22,32,2,6,2, 7,  0.8,'Ambush Crit',           '+0.8% Critical Strike'),
(22,33,4,6,2, 3,  2.0,'Brawler Endurance',     '+2.0% Stamina');

-- Board 23 — Subtlety: Phantom  (Agility%, Crit%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(23, 1,3,3,4, 0,  0.0,'The Phantom',           'They never see you coming.'),
(23, 2,3,1,1, 2,138.0,'Shadow Agility',        '+138 Agility'),
(23, 3,2,2,1,10,118.0,'Ambush Power',          '+118 Attack Power'),
(23, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(23, 5,4,2,1, 2,138.0,'Vanish Agility',        '+138 Agility'),
(23, 6,2,3,1,10,118.0,'Garrote Power',         '+118 Attack Power'),
(23, 7,4,3,1, 2,138.0,'Premeditation Agility', '+138 Agility'),
(23, 8,2,4,1, 3,110.0,'Phantom Endurance',     '+110 Stamina'),
(23, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(23,10,4,4,1,10,118.0,'Hemorrhage Power',      '+118 Attack Power'),
(23,11,3,5,1, 2,138.0,'Shadow Dance Agility',  '+138 Agility'),
(23,12,1,1,0, 2, 64.0,'Ghost Agility',         '+64 Agility'),
(23,13,2,1,0, 3, 50.0,'Smoke Endurance',       '+50 Stamina'),
(23,14,4,1,0, 2, 64.0,'Stealth Agility',       '+64 Agility'),
(23,15,5,1,0,10, 52.0,'Shadow Blow',           '+52 Attack Power'),
(23,16,1,2,0,10, 52.0,'Cheap Shot Power',      '+52 Attack Power'),
(23,17,5,2,0, 2, 64.0,'Evasion Agility',       '+64 Agility'),
(23,18,1,3,0, 2, 64.0,'Kidney Shot Agility',   '+64 Agility'),
(23,19,5,3,0, 3, 50.0,'Dark Reserves',         '+50 Stamina'),
(23,20,1,4,0, 2, 64.0,'Cheat Death Agility',   '+64 Agility'),
(23,21,5,4,0,10, 52.0,'Shadowstep Power',      '+52 Attack Power'),
(23,22,1,5,0, 3, 50.0,'Subtlety Endurance',    '+50 Stamina'),
(23,23,2,5,0, 2, 64.0,'Night Form Agility',    '+64 Agility'),
(23,24,4,5,0,10, 52.0,'Find Weakness Power',   '+52 Attack Power'),
(23,25,5,5,0, 2, 64.0,'Preparation Agility',   '+64 Agility'),
(23,26,2,0,2, 2,  2.5,'Phantom Swiftness',     '+2.5% Agility'),
(23,27,4,0,2, 7,  1.5,'Shadow Strike Crit',    '+1.5% Critical Strike'),
(23,28,0,2,2, 2,  2.5,'Ghost Runner Speed',    '+2.5% Agility'),
(23,29,6,2,2, 7,  1.5,'Ambush Crit Surge',     '+1.5% Critical Strike'),
(23,30,0,4,2,10,  2.5,'Hemorrhage Fury',       '+2.5% Attack Power'),
(23,31,6,4,2, 2,  2.5,'Night Walker',          '+2.5% Agility'),
(23,32,2,6,2, 7,  1.5,'Death Mark Precision',  '+1.5% Critical Strike'),
(23,33,4,6,2, 3,  2.0,'Phantom Endurance',     '+2.0% Stamina');

-- ============================================================
-- PRIEST SPEC BOARDS
-- ============================================================

-- Board 24 — Discipline: Bastion  (Spirit%, SpellPower%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(24, 1,3,3,4, 0,  0.0,'The Bastion of Faith',  'An unbreakable shield of light.'),
(24, 2,3,1,1, 5,125.0,'Grace Spirit',          '+125 Spirit'),
(24, 3,2,2,1, 9,118.0,'Power Word Shield Power','+118 Spell Power'),
(24, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(24, 5,4,2,1, 4,122.0,'Discipline Mind',       '+122 Intellect'),
(24, 6,2,3,1, 5,125.0,'Penance Spirit',        '+125 Spirit'),
(24, 7,4,3,1, 9,118.0,'Pain Suppression Power','+118 Spell Power'),
(24, 8,2,4,1, 4,122.0,'Rapture Mind',          '+122 Intellect'),
(24, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(24,10,4,4,1, 5,125.0,'Divine Aegis Spirit',   '+125 Spirit'),
(24,11,3,5,1, 9,118.0,'Atonement Power',       '+118 Spell Power'),
(24,12,1,1,0, 5, 58.0,'Renewed Hope',          '+58 Spirit'),
(24,13,2,1,0, 4, 55.0,'Train of Thought',      '+55 Intellect'),
(24,14,4,1,0, 5, 58.0,'Body and Soul Spirit',  '+58 Spirit'),
(24,15,5,1,0, 3, 42.0,'Disc Endurance',        '+42 Stamina'),
(24,16,1,2,0, 4, 55.0,'Focused Will',          '+55 Intellect'),
(24,17,5,2,0, 9, 52.0,'Inner Focus Power',     '+52 Spell Power'),
(24,18,1,3,0, 5, 58.0,'Reflective Shield',     '+58 Spirit'),
(24,19,5,3,0, 4, 55.0,'Enlightenment Mind',    '+55 Intellect'),
(24,20,1,4,0, 9, 52.0,'Empowered Healing',     '+52 Spell Power'),
(24,21,5,4,0, 5, 58.0,'Soul Warding Spirit',   '+58 Spirit'),
(24,22,1,5,0, 4, 55.0,'Borrowed Time Mind',    '+55 Intellect'),
(24,23,2,5,0, 3, 42.0,'Holy Body',             '+42 Stamina'),
(24,24,4,5,0, 9, 52.0,'Surge of Light',        '+52 Spell Power'),
(24,25,5,5,0, 4, 55.0,'Seraphic Mind',         '+55 Intellect'),
(24,26,2,0,2, 5,  2.0,'Wellspring of Purity',  '+2.0% Spirit'),
(24,27,4,0,2, 9,  2.0,'Shield Surge',          '+2.0% Spell Power'),
(24,28,0,2,2, 4,  2.0,'Luminous Mind',         '+2.0% Intellect'),
(24,29,6,2,2, 5,  2.0,'Flowing Grace',         '+2.0% Spirit'),
(24,30,0,4,2, 8,  0.8,'Prayer Tempo',          '+0.8% Haste'),
(24,31,6,4,2, 9,  2.0,'Aegis Power',           '+2.0% Spell Power'),
(24,32,2,6,2, 7,  0.8,'Holy Crit',             '+0.8% Critical Strike'),
(24,33,4,6,2, 3,  2.0,'Disc Endurance Surge',  '+2.0% Stamina');

-- Board 25 — Holy: Serenity  (SpellPower%, Spirit%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(25, 1,3,3,4, 0,  0.0,'The Holy Serenity',     'Your heals flow like rivers of light.'),
(25, 2,3,1,1, 9,125.0,'Holy Word Power',       '+125 Spell Power'),
(25, 3,2,2,1, 4,120.0,'Serenity Mind',         '+120 Intellect'),
(25, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(25, 5,4,2,1, 5,118.0,'Desperate Prayer Spirit','+118 Spirit'),
(25, 6,2,3,1, 9,125.0,'Circle of Healing Power','+125 Spell Power'),
(25, 7,4,3,1, 4,120.0,'Empowered Renew Mind',  '+120 Intellect'),
(25, 8,2,4,1, 5,118.0,'Guardian Spirit',       '+118 Spirit'),
(25, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(25,10,4,4,1, 9,125.0,'Prayer of Healing Power','+125 Spell Power'),
(25,11,3,5,1, 4,120.0,'Inspiration Mind',      '+120 Intellect'),
(25,12,1,1,0, 9, 56.0,'Heal Surge',            '+56 Spell Power'),
(25,13,2,1,0, 5, 54.0,'Gentle Light',          '+54 Spirit'),
(25,14,4,1,0, 4, 56.0,'Holy Insight',          '+56 Intellect'),
(25,15,5,1,0, 3, 42.0,'Sacred Endurance',      '+42 Stamina'),
(25,16,1,2,0, 5, 54.0,'Soothing Grace',        '+54 Spirit'),
(25,17,5,2,0, 9, 56.0,'Binding Heal Power',    '+56 Spell Power'),
(25,18,1,3,0, 4, 56.0,'Surge of Faith',        '+56 Intellect'),
(25,19,5,3,0, 5, 54.0,'Angelic Spirit',        '+54 Spirit'),
(25,20,1,4,0, 9, 56.0,'Renew Surge',           '+56 Spell Power'),
(25,21,5,4,0, 4, 56.0,'Prayer Scholar',        '+56 Intellect'),
(25,22,1,5,0, 5, 54.0,'Blessed Calm',          '+54 Spirit'),
(25,23,2,5,0, 3, 42.0,'Holy Vigor',            '+42 Stamina'),
(25,24,4,5,0, 9, 56.0,'Flash of Light',        '+56 Spell Power'),
(25,25,5,5,0, 4, 56.0,'Divine Serenity',       '+56 Intellect'),
(25,26,2,0,2, 9,  2.0,'Holy Radiance Surge',   '+2.0% Spell Power'),
(25,27,4,0,2, 5,  2.0,'River of Renewal',      '+2.0% Spirit'),
(25,28,0,2,2, 4,  2.0,'Seraphic Scholar',      '+2.0% Intellect'),
(25,29,6,2,2, 9,  2.0,'Prayer of Mending Power','+2.0% Spell Power'),
(25,30,0,4,2, 8,  0.8,'Holy Tempo',            '+0.8% Haste'),
(25,31,6,4,2, 5,  2.0,'Wellspring Spirit',     '+2.0% Spirit'),
(25,32,2,6,2, 7,  0.8,'Holy Crit Surge',       '+0.8% Critical Strike'),
(25,33,4,6,2, 3,  2.0,'Holy Body',             '+2.0% Stamina');

-- Board 26 — Shadow: Void  (SpellPower%, Haste%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(26, 1,3,3,4, 0,  0.0,'The Void Path',         'The shadow is not darkness. It is truth.'),
(26, 2,3,1,1, 9,130.0,'Shadow Weave Power',    '+130 Spell Power'),
(26, 3,2,2,1, 4,122.0,'Void Scholar',          '+122 Intellect'),
(26, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(26, 5,4,2,1, 9,130.0,'Mind Flay Power',       '+130 Spell Power'),
(26, 6,2,3,1, 4,122.0,'Devouring Plague Mind', '+122 Intellect'),
(26, 7,4,3,1, 9,130.0,'Vampiric Touch Power',  '+130 Spell Power'),
(26, 8,2,4,1, 3,110.0,'Shadow Body',           '+110 Stamina'),
(26, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(26,10,4,4,1, 4,122.0,'Shadowform Mind',       '+122 Intellect'),
(26,11,3,5,1, 9,130.0,'Mind Blast Surge',      '+130 Spell Power'),
(26,12,1,1,0, 4, 56.0,'Void Acuity',           '+56 Intellect'),
(26,13,2,1,0, 3, 50.0,'Shadow Endurance',      '+50 Stamina'),
(26,14,4,1,0, 9, 58.0,'Psychic Scream Power',  '+58 Spell Power'),
(26,15,5,1,0, 5, 45.0,'Dark Calm',             '+45 Spirit'),
(26,16,1,2,0, 9, 58.0,'Twisted Faith Power',   '+58 Spell Power'),
(26,17,5,2,0, 4, 56.0,'Void Vision',           '+56 Intellect'),
(26,18,1,3,0, 4, 56.0,'Pain and Suffering',    '+56 Intellect'),
(26,19,5,3,0, 3, 50.0,'Void Body',             '+50 Stamina'),
(26,20,1,4,0, 9, 58.0,'Dispersion Power',      '+58 Spell Power'),
(26,21,5,4,0, 4, 56.0,'Mental Strength',       '+56 Intellect'),
(26,22,1,5,0, 3, 50.0,'Shadow Reserves',       '+50 Stamina'),
(26,23,2,5,0, 9, 58.0,'Shadowfiend Power',     '+58 Spell Power'),
(26,24,4,5,0, 4, 56.0,'Phantasm Mind',         '+56 Intellect'),
(26,25,5,5,0, 9, 58.0,'Void Surge',            '+58 Spell Power'),
(26,26,2,0,2, 9,  2.5,'Shadow Torrent',        '+2.5% Spell Power'),
(26,27,4,0,2, 8,  1.2,'Void Tempo',            '+1.2% Haste'),
(26,28,0,2,2, 4,  2.0,'Infinite Malice Mind',  '+2.0% Intellect'),
(26,29,6,2,2, 9,  2.5,'Devouring Power',       '+2.5% Spell Power'),
(26,30,0,4,2, 8,  1.2,'Shadow Speed',          '+1.2% Haste'),
(26,31,6,4,2, 9,  2.5,'Mind Sear Surge',       '+2.5% Spell Power'),
(26,32,2,6,2, 7,  0.8,'Shadow Crit',           '+0.8% Critical Strike'),
(26,33,4,6,2, 3,  2.0,'Void Endurance',        '+2.0% Stamina');

-- ============================================================
-- DEATH KNIGHT SPEC BOARDS
-- ============================================================

-- Board 27 — Blood: Crimson  (Stamina%, Armor%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(27, 1,3,3,4, 0,  0.0,'The Crimson Path',      'Blood is your shield and your weapon.'),
(27, 2,3,1,1, 3,130.0,'Blood Pool Stamina',    '+130 Stamina'),
(27, 3,2,2,1, 6,120.0,'Crimson Plating',       '+120 Armor'),
(27, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(27, 5,4,2,1, 1,125.0,'Death Strike Strength', '+125 Strength'),
(27, 6,2,3,1, 3,130.0,'Vampiric Blood',        '+130 Stamina'),
(27, 7,4,3,1, 6,120.0,'Bone Shield Plating',   '+120 Armor'),
(27, 8,2,4,1, 3,130.0,'Dancing Rune Endurance','+130 Stamina'),
(27, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(27,10,4,4,1, 1,125.0,'Heart Strike Power',    '+125 Strength'),
(27,11,3,5,1, 3,130.0,'Blood Presence Body',   '+130 Stamina'),
(27,12,1,1,0, 3, 62.0,'Iron Body',             '+62 Stamina'),
(27,13,2,1,0, 6, 56.0,'Blood Armor',           '+56 Armor'),
(27,14,4,1,0, 3, 62.0,'Crimson Reserve',       '+62 Stamina'),
(27,15,5,1,0, 1, 58.0,'Death Might',           '+58 Strength'),
(27,16,1,2,0, 6, 56.0,'Sanguine Plate',        '+56 Armor'),
(27,17,5,2,0, 3, 62.0,'Blood Shield Body',     '+62 Stamina'),
(27,18,1,3,0, 3, 62.0,'Mark of Blood Body',    '+62 Stamina'),
(27,19,5,3,0, 6, 56.0,'Scent of Blood Armor',  '+56 Armor'),
(27,20,1,4,0, 1, 58.0,'Rune Tap Strength',     '+58 Strength'),
(27,21,5,4,0, 3, 62.0,'Frost Presence Body',   '+62 Stamina'),
(27,22,1,5,0, 6, 56.0,'Will of the Necropolis','+56 Armor'),
(27,23,2,5,0, 3, 62.0,'Scarlet Fever Body',    '+62 Stamina'),
(27,24,4,5,0, 1, 58.0,'Blade Barrier Strength','+58 Strength'),
(27,25,5,5,0, 3, 62.0,'Endless Undeath Body',  '+62 Stamina'),
(27,26,2,0,2, 3,  2.5,'Crimson Endurance',     '+2.5% Stamina'),
(27,27,4,0,2, 6,  2.0,'Blood Fortress',        '+2.0% Armor'),
(27,28,0,2,2, 3,  2.5,'Lifeblood Reserve',     '+2.5% Stamina'),
(27,29,6,2,2, 6,  2.0,'Necrotic Plating',      '+2.0% Armor'),
(27,30,0,4,2, 1,  2.0,'Death Knight Strength', '+2.0% Strength'),
(27,31,6,4,2, 3,  2.5,'Undying Constitution',  '+2.5% Stamina'),
(27,32,2,6,2, 7,  0.8,'Blood Crit',            '+0.8% Critical Strike'),
(27,33,4,6,2, 6,  2.0,'Iron Will Armor',       '+2.0% Armor');

-- Board 28 — Frost: Glacial  (Crit%, AP%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(28, 1,3,3,4, 0,  0.0,'The Glacial Throne',    'Your blade freezes what it does not slay.'),
(28, 2,3,1,1, 1,135.0,'Frost Strength',        '+135 Strength'),
(28, 3,2,2,1,10,125.0,'Obliterate Power',      '+125 Attack Power'),
(28, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(28, 5,4,2,1, 1,135.0,'Howling Blast Strength','+135 Strength'),
(28, 6,2,3,1,10,125.0,'Frost Strike Power',    '+125 Attack Power'),
(28, 7,4,3,1, 1,135.0,'Killing Machine Strength','+135 Strength'),
(28, 8,2,4,1, 3,115.0,'Icy Endurance',         '+115 Stamina'),
(28, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(28,10,4,4,1,10,125.0,'Pillar of Frost Power', '+125 Attack Power'),
(28,11,3,5,1, 1,135.0,'Glacial Might',         '+135 Strength'),
(28,12,1,1,0, 1, 62.0,'Frost Sinew',           '+62 Strength'),
(28,13,2,1,0, 3, 55.0,'Ice Body',              '+55 Stamina'),
(28,14,4,1,0, 1, 62.0,'Icy Grasp Strength',    '+62 Strength'),
(28,15,5,1,0,10, 55.0,'Chill Strike AP',       '+55 Attack Power'),
(28,16,1,2,0,10, 55.0,'Runic Empowerment AP',  '+55 Attack Power'),
(28,17,5,2,0, 1, 62.0,'Deathchill Strength',   '+62 Strength'),
(28,18,1,3,0, 1, 62.0,'Lichborne Strength',    '+62 Strength'),
(28,19,5,3,0, 3, 55.0,'Glacial Shield Body',   '+55 Stamina'),
(28,20,1,4,0,10, 55.0,'Rime Frost AP',         '+55 Attack Power'),
(28,21,5,4,0, 1, 62.0,'Frozen Heart',          '+62 Strength'),
(28,22,1,5,0, 3, 55.0,'Winter Body',           '+55 Stamina'),
(28,23,2,5,0, 1, 62.0,'Merciless Frost',       '+62 Strength'),
(28,24,4,5,0,10, 55.0,'Glacial Advance AP',    '+55 Attack Power'),
(28,25,5,5,0, 1, 62.0,'Absolute Zero Might',   '+62 Strength'),
(28,26,2,0,2, 7,  1.5,'Frozen Crit',           '+1.5% Critical Strike'),
(28,27,4,0,2,10,  2.5,'Glacial Fury',          '+2.5% Attack Power'),
(28,28,0,2,2, 1,  2.0,'Frost Colossus',        '+2.0% Strength'),
(28,29,6,2,2, 7,  1.5,'Killing Machine Crit',  '+1.5% Critical Strike'),
(28,30,0,4,2,10,  2.5,'Obliterate Fury',       '+2.5% Attack Power'),
(28,31,6,4,2, 1,  2.0,'Absolute Might',        '+2.0% Strength'),
(28,32,2,6,2, 7,  1.5,'Icy Touch Crit',        '+1.5% Critical Strike'),
(28,33,4,6,2, 3,  2.0,'Frost Endurance',       '+2.0% Stamina');

-- Board 29 — Unholy: Plague  (AP%, Haste%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(29, 1,3,3,4, 0,  0.0,'The Plague Lord',       'Disease is your gift. Death is your art.'),
(29, 2,3,1,1, 1,132.0,'Unholy Might',          '+132 Strength'),
(29, 3,2,2,1,10,128.0,'Scourge Strike Power',  '+128 Attack Power'),
(29, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(29, 5,4,2,1,10,128.0,'Death Coil Power',      '+128 Attack Power'),
(29, 6,2,3,1, 1,132.0,'Epidemic Strength',     '+132 Strength'),
(29, 7,4,3,1,10,128.0,'Summon Gargoyle Power', '+128 Attack Power'),
(29, 8,2,4,1, 3,112.0,'Plague Endurance',      '+112 Stamina'),
(29, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(29,10,4,4,1, 1,132.0,'Sudden Doom Strength',  '+132 Strength'),
(29,11,3,5,1,10,128.0,'Army of the Dead Power','+128 Attack Power'),
(29,12,1,1,0, 1, 60.0,'Plague Might',          '+60 Strength'),
(29,13,2,1,0, 3, 52.0,'Plague Body',           '+52 Stamina'),
(29,14,4,1,0,10, 58.0,'Blood Plague AP',       '+58 Attack Power'),
(29,15,5,1,0, 1, 60.0,'Frost Fever Strength',  '+60 Strength'),
(29,16,1,2,0,10, 58.0,'Unholy Blight AP',      '+58 Attack Power'),
(29,17,5,2,0, 3, 52.0,'Morbid Body',           '+52 Stamina'),
(29,18,1,3,0, 1, 60.0,'Wandering Plague Might','+60 Strength'),
(29,19,5,3,0,10, 58.0,'Necrosis AP',           '+58 Attack Power'),
(29,20,1,4,0, 3, 52.0,'Plague Reserve',        '+52 Stamina'),
(29,21,5,4,0, 1, 60.0,'Magic Suppression',     '+60 Strength'),
(29,22,1,5,0,10, 58.0,'Corpse Explosion AP',   '+58 Attack Power'),
(29,23,2,5,0, 3, 52.0,'Unholy Endurance',      '+52 Stamina'),
(29,24,4,5,0, 1, 60.0,'Bone Shields Strength', '+60 Strength'),
(29,25,5,5,0,10, 58.0,'Death Rune AP',         '+58 Attack Power'),
(29,26,2,0,2,10,  2.5,'Plague Surge',          '+2.5% Attack Power'),
(29,27,4,0,2, 8,  1.2,'Unholy Tempo',          '+1.2% Haste'),
(29,28,0,2,2, 1,  2.0,'Scourge Might',         '+2.0% Strength'),
(29,29,6,2,2,10,  2.5,'Death Coil Fury',       '+2.5% Attack Power'),
(29,30,0,4,2, 8,  1.2,'Epidemic Tempo',        '+1.2% Haste'),
(29,31,6,4,2,10,  2.5,'Army Fury',             '+2.5% Attack Power'),
(29,32,2,6,2, 7,  0.8,'Plague Crit',           '+0.8% Critical Strike'),
(29,33,4,6,2, 3,  2.0,'Corpse Endurance',      '+2.0% Stamina');

-- ============================================================
-- SHAMAN SPEC BOARDS
-- ============================================================

-- Board 30 — Elemental: Maelstrom  (SpellPower%, Haste%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(30, 1,3,3,4, 0,  0.0,'The Maelstrom',         'Lightning does not ask permission.'),
(30, 2,3,1,1, 4,130.0,'Elemental Mastery Mind','+130 Intellect'),
(30, 3,2,2,1, 9,128.0,'Lightning Bolt Power',  '+128 Spell Power'),
(30, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(30, 5,4,2,1, 4,130.0,'Lava Burst Mind',       '+130 Intellect'),
(30, 6,2,3,1, 9,128.0,'Chain Lightning Power', '+128 Spell Power'),
(30, 7,4,3,1, 4,130.0,'Thunderstorm Mind',     '+130 Intellect'),
(30, 8,2,4,1, 3,112.0,'Elemental Endurance',   '+112 Stamina'),
(30, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(30,10,4,4,1, 9,128.0,'Fire Nova Power',       '+128 Spell Power'),
(30,11,3,5,1, 4,130.0,'Maelstrom Mind',        '+130 Intellect'),
(30,12,1,1,0, 4, 60.0,'Storm Clarity',         '+60 Intellect'),
(30,13,2,1,0, 5, 50.0,'Thunder Calm',          '+50 Spirit'),
(30,14,4,1,0, 9, 58.0,'Earth Shock Power',     '+58 Spell Power'),
(30,15,5,1,0, 3, 48.0,'Totem Endurance',       '+48 Stamina'),
(30,16,1,2,0, 9, 58.0,'Flame Shock Power',     '+58 Spell Power'),
(30,17,5,2,0, 4, 60.0,'Focused Storm',         '+60 Intellect'),
(30,18,1,3,0, 4, 60.0,'Static Discharge Mind', '+60 Intellect'),
(30,19,5,3,0, 5, 50.0,'Ancestor Serenity',     '+50 Spirit'),
(30,20,1,4,0, 9, 58.0,'Elemental Oath Power',  '+58 Spell Power'),
(30,21,5,4,0, 4, 60.0,'Fulmination Mind',      '+60 Intellect'),
(30,22,1,5,0, 3, 48.0,'Storm Endurance',       '+48 Stamina'),
(30,23,2,5,0, 4, 60.0,'Lightning Shield Mind', '+60 Intellect'),
(30,24,4,5,0, 9, 58.0,'Lava Surge Power',      '+58 Spell Power'),
(30,25,5,5,0, 4, 60.0,'Maelstrom Weapon Mind', '+60 Intellect'),
(30,26,2,0,2, 9,  2.5,'Maelstrom Surge',       '+2.5% Spell Power'),
(30,27,4,0,2, 8,  1.2,'Storm Speed',           '+1.2% Haste'),
(30,28,0,2,2, 4,  2.0,'Elemental Clarity',     '+2.0% Intellect'),
(30,29,6,2,2, 9,  2.5,'Thunderstrike Power',   '+2.5% Spell Power'),
(30,30,0,4,2, 8,  1.2,'Chain Tempo',           '+1.2% Haste'),
(30,31,6,4,2, 9,  2.5,'Lava Burst Surge',      '+2.5% Spell Power'),
(30,32,2,6,2, 7,  0.8,'Elemental Crit',        '+0.8% Critical Strike'),
(30,33,4,6,2, 3,  2.0,'Storm Body',            '+2.0% Stamina');

-- Board 31 — Enhancement: Earthbind  (AP%, Agility%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(31, 1,3,3,4, 0,  0.0,'The Earthbind',         'Earth and weapon strike as one.'),
(31, 2,3,1,1, 2,132.0,'Enhancement Agility',   '+132 Agility'),
(31, 3,2,2,1,10,125.0,'Stormstrike Power',     '+125 Attack Power'),
(31, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(31, 5,4,2,1, 1,128.0,'Lava Lash Strength',    '+128 Strength'),
(31, 6,2,3,1, 2,132.0,'Feral Spirit Agility',  '+132 Agility'),
(31, 7,4,3,1,10,125.0,'Windfury Power',        '+125 Attack Power'),
(31, 8,2,4,1, 3,112.0,'Earthen Endurance',     '+112 Stamina'),
(31, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(31,10,4,4,1, 2,132.0,'Maelstrom Weapon Agility','+132 Agility'),
(31,11,3,5,1,10,125.0,'Primal Fury Power',     '+125 Attack Power'),
(31,12,1,1,0, 2, 60.0,'Earth Agility',         '+60 Agility'),
(31,13,2,1,0,10, 56.0,'Earthbind AP',          '+56 Attack Power'),
(31,14,4,1,0, 1, 58.0,'Stone Fist Strength',   '+58 Strength'),
(31,15,5,1,0, 3, 50.0,'Earth Body',            '+50 Stamina'),
(31,16,1,2,0,10, 56.0,'Dual Wield Mastery AP', '+56 Attack Power'),
(31,17,5,2,0, 2, 60.0,'Wind Agility',          '+60 Agility'),
(31,18,1,3,0, 2, 60.0,'Ancestral Agility',     '+60 Agility'),
(31,19,5,3,0, 3, 50.0,'Primal Reserves',       '+50 Stamina'),
(31,20,1,4,0, 1, 58.0,'Rockbiter Strength',    '+58 Strength'),
(31,21,5,4,0, 2, 60.0,'Booming Strikes Agility','+60 Agility'),
(31,22,1,5,0, 3, 50.0,'Shaman Endurance',      '+50 Stamina'),
(31,23,2,5,0, 2, 60.0,'Mental Quickness Agility','+60 Agility'),
(31,24,4,5,0,10, 56.0,'Unleashed Rage AP',     '+56 Attack Power'),
(31,25,5,5,0, 2, 60.0,'Static Shock Agility',  '+60 Agility'),
(31,26,2,0,2, 2,  2.5,'Earthen Swiftness',     '+2.5% Agility'),
(31,27,4,0,2,10,  2.5,'Windfury Surge',        '+2.5% Attack Power'),
(31,28,0,2,2, 8,  1.2,'Enhancement Tempo',     '+1.2% Haste'),
(31,29,6,2,2, 2,  2.5,'Feral Agility Surge',   '+2.5% Agility'),
(31,30,0,4,2,10,  2.5,'Stormstrike Surge',     '+2.5% Attack Power'),
(31,31,6,4,2, 1,  2.0,'Earthen Might',         '+2.0% Strength'),
(31,32,2,6,2, 7,  0.8,'Elemental Precision',   '+0.8% Critical Strike'),
(31,33,4,6,2, 3,  2.0,'Earth Endurance',       '+2.0% Stamina');

-- Board 32 — Restoration: Tide  (Spirit%, SpellPower%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(32, 1,3,3,4, 0,  0.0,'The Healing Tide',      'The tide mends all that the storm breaks.'),
(32, 2,3,1,1, 5,128.0,'Tidal Waves Spirit',    '+128 Spirit'),
(32, 3,2,2,1, 9,122.0,'Riptide Power',         '+122 Spell Power'),
(32, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(32, 5,4,2,1, 4,125.0,'Resto Intellect',       '+125 Intellect'),
(32, 6,2,3,1, 5,128.0,'Chain Heal Spirit',     '+128 Spirit'),
(32, 7,4,3,1, 9,122.0,'Healing Rain Power',    '+122 Spell Power'),
(32, 8,2,4,1, 4,125.0,'Mana Tide Mind',        '+125 Intellect'),
(32, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(32,10,4,4,1, 5,128.0,'Ancestral Healing Spirit','+128 Spirit'),
(32,11,3,5,1, 9,122.0,'Earth Shield Power',    '+122 Spell Power'),
(32,12,1,1,0, 5, 58.0,'River Spirit',          '+58 Spirit'),
(32,13,2,1,0, 4, 56.0,'Totem Mind',            '+56 Intellect'),
(32,14,4,1,0, 9, 55.0,'Healing Wave Power',    '+55 Spell Power'),
(32,15,5,1,0, 3, 45.0,'Tide Endurance',        '+45 Stamina'),
(32,16,1,2,0, 4, 56.0,'Focused Mana',          '+56 Intellect'),
(32,17,5,2,0, 5, 58.0,'Nourish Spirit',        '+58 Spirit'),
(32,18,1,3,0, 5, 58.0,'Purification Spirit',   '+58 Spirit'),
(32,19,5,3,0, 4, 56.0,'Deep Healing Mind',     '+56 Intellect'),
(32,20,1,4,0, 9, 55.0,'Ancestral Fortitude',   '+55 Spell Power'),
(32,21,5,4,0, 5, 58.0,'Cleanse Spirit',        '+58 Spirit'),
(32,22,1,5,0, 3, 45.0,'Shaman Vigor',          '+45 Stamina'),
(32,23,2,5,0, 9, 55.0,'Healing Stream Power',  '+55 Spell Power'),
(32,24,4,5,0, 4, 56.0,'Mana Spring Mind',      '+56 Intellect'),
(32,25,5,5,0, 5, 58.0,'Tide Caller Spirit',    '+58 Spirit'),
(32,26,2,0,2, 5,  2.0,'Ancestral Spirit',      '+2.0% Spirit'),
(32,27,4,0,2, 9,  2.5,'Riptide Surge',         '+2.5% Spell Power'),
(32,28,0,2,2, 4,  2.0,'Tidal Intellect',       '+2.0% Intellect'),
(32,29,6,2,2, 5,  2.0,'Ocean Soul',            '+2.0% Spirit'),
(32,30,0,4,2, 8,  0.8,'Tidal Tempo',           '+0.8% Haste'),
(32,31,6,4,2, 9,  2.5,'Chain Heal Surge',      '+2.5% Spell Power'),
(32,32,2,6,2, 7,  0.8,'Earthen Crit',          '+0.8% Critical Strike'),
(32,33,4,6,2, 3,  2.0,'Tidal Endurance',       '+2.0% Stamina');

-- ============================================================
-- MAGE SPEC BOARDS
-- ============================================================

-- Board 33 — Arcane: Singularity  (SpellPower%, Intellect%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(33, 1,3,3,4, 0,  0.0,'The Arcane Singularity','Reality collapses into your will.'),
(33, 2,3,1,1, 4,138.0,'Arcane Power Mind',     '+138 Intellect'),
(33, 3,2,2,1, 9,132.0,'Arcane Blast Power',    '+132 Spell Power'),
(33, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(33, 5,4,2,1, 4,138.0,'Arcane Barrage Mind',   '+138 Intellect'),
(33, 6,2,3,1, 9,132.0,'Arcane Missiles Power', '+132 Spell Power'),
(33, 7,4,3,1, 4,138.0,'Presence of Mind',      '+138 Intellect'),
(33, 8,2,4,1, 5,115.0,'Arcane Spirit',         '+115 Spirit'),
(33, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(33,10,4,4,1, 9,132.0,'Arcane Explosion Power','+132 Spell Power'),
(33,11,3,5,1, 4,138.0,'Infinite Arcane',       '+138 Intellect'),
(33,12,1,1,0, 4, 65.0,'Arcane Scholar',        '+65 Intellect'),
(33,13,2,1,0, 5, 52.0,'Mana Flux',             '+52 Spirit'),
(33,14,4,1,0, 9, 62.0,'Arcane Shockwave Power','+62 Spell Power'),
(33,15,5,1,0, 3, 40.0,'Mage Endurance',        '+40 Stamina'),
(33,16,1,2,0, 9, 62.0,'Nether Vortex Power',   '+62 Spell Power'),
(33,17,5,2,0, 4, 65.0,'Arcane Flows Mind',     '+65 Intellect'),
(33,18,1,3,0, 4, 65.0,'Spellpower Focus',      '+65 Intellect'),
(33,19,5,3,0, 5, 52.0,'Mana Gem Spirit',       '+52 Spirit'),
(33,20,1,4,0, 9, 62.0,'Slow Power',            '+62 Spell Power'),
(33,21,5,4,0, 4, 65.0,'Incanter Concentration','+65 Intellect'),
(33,22,1,5,0, 4, 65.0,'Torment the Weak Mind', '+65 Intellect'),
(33,23,2,5,0, 3, 40.0,'Conjured Body',         '+40 Stamina'),
(33,24,4,5,0, 9, 62.0,'Mana Shield Power',     '+62 Spell Power'),
(33,25,5,5,0, 4, 65.0,'Arcane Concentration',  '+65 Intellect'),
(33,26,2,0,2, 9,  2.5,'Arcane Surge',          '+2.5% Spell Power'),
(33,27,4,0,2, 4,  2.5,'Nexus Scholar Mind',    '+2.5% Intellect'),
(33,28,0,2,2, 9,  2.5,'Prismatic Explosion',   '+2.5% Spell Power'),
(33,29,6,2,2, 4,  2.5,'Infinite Intelligence', '+2.5% Intellect'),
(33,30,0,4,2, 8,  1.2,'Arcane Velocity',       '+1.2% Haste'),
(33,31,6,4,2, 9,  2.5,'Arcane Torrent Power',  '+2.5% Spell Power'),
(33,32,2,6,2, 7,  0.8,'Arcane Crit',           '+0.8% Critical Strike'),
(33,33,4,6,2, 5,  2.0,'Mana Wellspring',       '+2.0% Spirit');

-- Board 34 — Fire: Conflagration  (SpellPower%, Haste%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(34, 1,3,3,4, 0,  0.0,'The Conflagration',     'Everything burns. That is the point.'),
(34, 2,3,1,1, 9,135.0,'Fireball Power',        '+135 Spell Power'),
(34, 3,2,2,1, 4,130.0,'Pyromaniac Mind',       '+130 Intellect'),
(34, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(34, 5,4,2,1, 9,135.0,'Pyroblast Power',       '+135 Spell Power'),
(34, 6,2,3,1, 4,130.0,'Combustion Mind',       '+130 Intellect'),
(34, 7,4,3,1, 9,135.0,'Living Bomb Power',     '+135 Spell Power'),
(34, 8,2,4,1, 3,110.0,'Fire Endurance',        '+110 Stamina'),
(34, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(34,10,4,4,1, 4,130.0,'Firestarter Mind',      '+130 Intellect'),
(34,11,3,5,1, 9,135.0,'Inferno Surge',         '+135 Spell Power'),
(34,12,1,1,0, 9, 62.0,'Scorch Power',          '+62 Spell Power'),
(34,13,2,1,0, 4, 60.0,'Fire Scholar',          '+60 Intellect'),
(34,14,4,1,0, 9, 62.0,'Flame Strike Power',    '+62 Spell Power'),
(34,15,5,1,0, 3, 42.0,'Flame Body',            '+42 Stamina'),
(34,16,1,2,0, 4, 60.0,'Heated Core',           '+60 Intellect'),
(34,17,5,2,0, 9, 62.0,'Blast Wave Power',      '+62 Spell Power'),
(34,18,1,3,0, 9, 62.0,'Dragon Breath Power',   '+62 Spell Power'),
(34,19,5,3,0, 4, 60.0,'Fiery Mind',            '+60 Intellect'),
(34,20,1,4,0, 9, 62.0,'Hot Streak Power',      '+62 Spell Power'),
(34,21,5,4,0, 4, 60.0,'Molten Armor Mind',     '+60 Intellect'),
(34,22,1,5,0, 3, 42.0,'Ash Body',              '+42 Stamina'),
(34,23,2,5,0, 9, 62.0,'Imp Scorch Power',      '+62 Spell Power'),
(34,24,4,5,0, 4, 60.0,'Ignite Mind',           '+60 Intellect'),
(34,25,5,5,0, 9, 62.0,'Melt Armor Power',      '+62 Spell Power'),
(34,26,2,0,2, 9,  2.5,'Inferno Surge',         '+2.5% Spell Power'),
(34,27,4,0,2, 8,  1.2,'Combustion Speed',      '+1.2% Haste'),
(34,28,0,2,2, 9,  2.5,'Pyroblast Surge',       '+2.5% Spell Power'),
(34,29,6,2,2, 8,  1.2,'Flame Tempo',           '+1.2% Haste'),
(34,30,0,4,2, 7,  1.0,'Living Bomb Crit',      '+1.0% Critical Strike'),
(34,31,6,4,2, 9,  2.5,'Fireball Torrent',      '+2.5% Spell Power'),
(34,32,2,6,2, 4,  2.0,'Ember Mind',            '+2.0% Intellect'),
(34,33,4,6,2, 3,  2.0,'Flame Endurance',       '+2.0% Stamina');

-- Board 35 — Frost: Glacialmind  (Haste%, SpellPower%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(35, 1,3,3,4, 0,  0.0,'The Glacial Mind',      'Absolute zero. Absolute control.'),
(35, 2,3,1,1, 4,132.0,'Frost Mastery Mind',    '+132 Intellect'),
(35, 3,2,2,1, 9,128.0,'Frostbolt Power',       '+128 Spell Power'),
(35, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(35, 5,4,2,1, 4,132.0,'Deep Freeze Mind',      '+132 Intellect'),
(35, 6,2,3,1, 9,128.0,'Ice Lance Power',       '+128 Spell Power'),
(35, 7,4,3,1, 4,132.0,'Brain Freeze Mind',     '+132 Intellect'),
(35, 8,2,4,1, 5,112.0,'Frost Spirit',          '+112 Spirit'),
(35, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(35,10,4,4,1, 9,128.0,'Blizzard Power',        '+128 Spell Power'),
(35,11,3,5,1, 4,132.0,'Shatter Mind',          '+132 Intellect'),
(35,12,1,1,0, 4, 62.0,'Icy Clarity',           '+62 Intellect'),
(35,13,2,1,0, 5, 52.0,'Glacial Calm',          '+52 Spirit'),
(35,14,4,1,0, 9, 60.0,'Cone of Cold Power',    '+60 Spell Power'),
(35,15,5,1,0, 3, 40.0,'Frost Body',            '+40 Stamina'),
(35,16,1,2,0, 9, 60.0,'Frost Nova Power',      '+60 Spell Power'),
(35,17,5,2,0, 4, 62.0,'Winter Chill Mind',     '+62 Intellect'),
(35,18,1,3,0, 4, 62.0,'Arctic Winds Mind',     '+62 Intellect'),
(35,19,5,3,0, 5, 52.0,'Frozen Tundra Spirit',  '+52 Spirit'),
(35,20,1,4,0, 9, 60.0,'Permafrost Power',      '+60 Spell Power'),
(35,21,5,4,0, 4, 62.0,'Cold Snap Mind',        '+62 Intellect'),
(35,22,1,5,0, 3, 40.0,'Glacial Reserves',      '+40 Stamina'),
(35,23,2,5,0, 9, 60.0,'Ring of Frost Power',   '+60 Spell Power'),
(35,24,4,5,0, 4, 62.0,'Summon Water Elemental','+62 Intellect'),
(35,25,5,5,0, 9, 60.0,'Frozen Orb Power',      '+60 Spell Power'),
(35,26,2,0,2, 8,  1.2,'Glacial Tempo',         '+1.2% Haste'),
(35,27,4,0,2, 9,  2.5,'Frostfire Surge',       '+2.5% Spell Power'),
(35,28,0,2,2, 8,  1.2,'Ice Speed',             '+1.2% Haste'),
(35,29,6,2,2, 4,  2.0,'Frozen Scholar',        '+2.0% Intellect'),
(35,30,0,4,2, 9,  2.5,'Shatter Surge',         '+2.5% Spell Power'),
(35,31,6,4,2, 8,  1.2,'Blizzard Tempo',        '+1.2% Haste'),
(35,32,2,6,2, 7,  1.0,'Fingers of Frost Crit', '+1.0% Critical Strike'),
(35,33,4,6,2, 3,  2.0,'Frost Endurance',       '+2.0% Stamina');

-- ============================================================
-- WARLOCK SPEC BOARDS
-- ============================================================

-- Board 36 — Affliction: Torment  (SpellPower%, Spirit%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(36, 1,3,3,4, 0,  0.0,'The Torment Path',      'Your curses outlast your enemies.'),
(36, 2,3,1,1, 9,132.0,'Corruption Power',      '+132 Spell Power'),
(36, 3,2,2,1, 4,128.0,'Affliction Mind',       '+128 Intellect'),
(36, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(36, 5,4,2,1, 5,120.0,'Siphon Life Spirit',    '+120 Spirit'),
(36, 6,2,3,1, 9,132.0,'Unstable Affliction',   '+132 Spell Power'),
(36, 7,4,3,1, 4,128.0,'Haunt Mind',            '+128 Intellect'),
(36, 8,2,4,1, 5,120.0,'Drain Life Spirit',     '+120 Spirit'),
(36, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(36,10,4,4,1, 9,132.0,'Shadow Bolt Power',     '+132 Spell Power'),
(36,11,3,5,1, 4,128.0,'Soulburn Mind',         '+128 Intellect'),
(36,12,1,1,0, 9, 62.0,'Curse Power',           '+62 Spell Power'),
(36,13,2,1,0, 5, 55.0,'Dark Renewal Spirit',   '+55 Spirit'),
(36,14,4,1,0, 4, 60.0,'Affliction Scholar',    '+60 Intellect'),
(36,15,5,1,0, 3, 45.0,'Dark Endurance',        '+45 Stamina'),
(36,16,1,2,0, 5, 55.0,'Shadow Embrace Spirit', '+55 Spirit'),
(36,17,5,2,0, 9, 62.0,'Agony Power',           '+62 Spell Power'),
(36,18,1,3,0, 4, 60.0,'Pandemic Mind',         '+60 Intellect'),
(36,19,5,3,0, 5, 55.0,'Soul Link Spirit',      '+55 Spirit'),
(36,20,1,4,0, 9, 62.0,'Nightfall Power',       '+62 Spell Power'),
(36,21,5,4,0, 4, 60.0,'Doom Mind',             '+60 Intellect'),
(36,22,1,5,0, 3, 45.0,'Malefic Body',          '+45 Stamina'),
(36,23,2,5,0, 9, 62.0,'Seed of Corruption',    '+62 Spell Power'),
(36,24,4,5,0, 5, 55.0,'Fel Spirit',            '+55 Spirit'),
(36,25,5,5,0, 4, 60.0,'Contagion Mind',        '+60 Intellect'),
(36,26,2,0,2, 9,  2.5,'Torment Surge',         '+2.5% Spell Power'),
(36,27,4,0,2, 5,  2.0,'Affliction Spirit',     '+2.0% Spirit'),
(36,28,0,2,2, 4,  2.0,'Malice Mind',           '+2.0% Intellect'),
(36,29,6,2,2, 9,  2.5,'Corruption Surge',      '+2.5% Spell Power'),
(36,30,0,4,2, 8,  0.8,'Dark Tempo',            '+0.8% Haste'),
(36,31,6,4,2, 5,  2.0,'Soulfire Spirit',       '+2.0% Spirit'),
(36,32,2,6,2, 7,  0.8,'Affliction Crit',       '+0.8% Critical Strike'),
(36,33,4,6,2, 3,  2.0,'Warlock Endurance',     '+2.0% Stamina');

-- Board 37 — Demonology: Pact  (Stamina%, SpellPower%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(37, 1,3,3,4, 0,  0.0,'The Dark Pact',         'You and your demon are inseparable.'),
(37, 2,3,1,1, 3,132.0,'Demonic Endurance',     '+132 Stamina'),
(37, 3,2,2,1, 9,128.0,'Metamorphosis Power',   '+128 Spell Power'),
(37, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(37, 5,4,2,1, 4,125.0,'Demonology Mind',       '+125 Intellect'),
(37, 6,2,3,1, 3,132.0,'Fel Armor Stamina',     '+132 Stamina'),
(37, 7,4,3,1, 9,128.0,'Demonic Empowerment',   '+128 Spell Power'),
(37, 8,2,4,1, 4,125.0,'Master Summoner Mind',  '+125 Intellect'),
(37, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(37,10,4,4,1, 3,132.0,'Soul Link Stamina',     '+132 Stamina'),
(37,11,3,5,1, 9,128.0,'Hand of Guldan Power',  '+128 Spell Power'),
(37,12,1,1,0, 3, 62.0,'Demonic Vitality',      '+62 Stamina'),
(37,13,2,1,0, 4, 58.0,'Demon Lord Mind',       '+58 Intellect'),
(37,14,4,1,0, 3, 62.0,'Fel Body',              '+62 Stamina'),
(37,15,5,1,0, 9, 56.0,'Demon Synergy Power',   '+56 Spell Power'),
(37,16,1,2,0, 4, 58.0,'Demonic Sacrifice Mind','+58 Intellect'),
(37,17,5,2,0, 3, 62.0,'Nether Protection Body','+62 Stamina'),
(37,18,1,3,0, 3, 62.0,'Molten Core Body',      '+62 Stamina'),
(37,19,5,3,0, 4, 58.0,'Decimation Mind',       '+58 Intellect'),
(37,20,1,4,0, 9, 56.0,'Inferno Power',         '+56 Spell Power'),
(37,21,5,4,0, 3, 62.0,'Demonic Pact Stamina',  '+62 Stamina'),
(37,22,1,5,0, 4, 58.0,'Ancient Grimoire Mind', '+58 Intellect'),
(37,23,2,5,0, 3, 62.0,'Fel Reserves',          '+62 Stamina'),
(37,24,4,5,0, 9, 56.0,'Chaos Wave Power',      '+56 Spell Power'),
(37,25,5,5,0, 3, 62.0,'Endless Pact Body',     '+62 Stamina'),
(37,26,2,0,2, 3,  2.5,'Demonic Constitution',  '+2.5% Stamina'),
(37,27,4,0,2, 9,  2.5,'Metamorphosis Surge',   '+2.5% Spell Power'),
(37,28,0,2,2, 4,  2.0,'Demon Lord Clarity',    '+2.0% Intellect'),
(37,29,6,2,2, 3,  2.5,'Fel Endurance',         '+2.5% Stamina'),
(37,30,0,4,2, 9,  2.5,'Hand of Guldan Surge',  '+2.5% Spell Power'),
(37,31,6,4,2, 3,  2.5,'Undying Pact',          '+2.5% Stamina'),
(37,32,2,6,2, 7,  0.8,'Demon Crit',            '+0.8% Critical Strike'),
(37,33,4,6,2, 8,  1.0,'Fel Tempo',             '+1.0% Haste');

-- Board 38 — Destruction: Chaos  (SpellPower%, Haste%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(38, 1,3,3,4, 0,  0.0,'The Chaos Path',        'Unleash. Burn. Destroy.'),
(38, 2,3,1,1, 9,138.0,'Chaos Bolt Power',      '+138 Spell Power'),
(38, 3,2,2,1, 4,128.0,'Destruction Mind',      '+128 Intellect'),
(38, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(38, 5,4,2,1, 9,138.0,'Conflagrate Power',     '+138 Spell Power'),
(38, 6,2,3,1, 4,128.0,'Shadowburn Mind',       '+128 Intellect'),
(38, 7,4,3,1, 9,138.0,'Immolate Power',        '+138 Spell Power'),
(38, 8,2,4,1, 3,110.0,'Chaos Endurance',       '+110 Stamina'),
(38, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(38,10,4,4,1, 4,128.0,'Backdraft Mind',        '+128 Intellect'),
(38,11,3,5,1, 9,138.0,'Shadowfury Power',      '+138 Spell Power'),
(38,12,1,1,0, 9, 65.0,'Rain of Fire Power',    '+65 Spell Power'),
(38,13,2,1,0, 4, 60.0,'Emberstorm Mind',       '+60 Intellect'),
(38,14,4,1,0, 9, 65.0,'Bane of Doom Power',    '+65 Spell Power'),
(38,15,5,1,0, 3, 42.0,'Fel Body',              '+42 Stamina'),
(38,16,1,2,0, 4, 60.0,'Ruin Mind',             '+60 Intellect'),
(38,17,5,2,0, 9, 65.0,'Incinerate Power',      '+65 Spell Power'),
(38,18,1,3,0, 9, 65.0,'Chaos Surge',           '+65 Spell Power'),
(38,19,5,3,0, 4, 60.0,'Havoc Mind',            '+60 Intellect'),
(38,20,1,4,0, 9, 65.0,'Soul Fire Power',       '+65 Spell Power'),
(38,21,5,4,0, 4, 60.0,'Destructive Reach',     '+60 Intellect'),
(38,22,1,5,0, 3, 42.0,'Ruination Body',        '+42 Stamina'),
(38,23,2,5,0, 9, 65.0,'Fire and Brimstone',    '+65 Spell Power'),
(38,24,4,5,0, 4, 60.0,'Aftermath Mind',        '+60 Intellect'),
(38,25,5,5,0, 9, 65.0,'Chaos Wave Power',      '+65 Spell Power'),
(38,26,2,0,2, 9,  2.5,'Chaos Torrent',         '+2.5% Spell Power'),
(38,27,4,0,2, 8,  1.2,'Infernal Speed',        '+1.2% Haste'),
(38,28,0,2,2, 9,  2.5,'Conflagrate Surge',     '+2.5% Spell Power'),
(38,29,6,2,2, 8,  1.2,'Chaos Tempo',           '+1.2% Haste'),
(38,30,0,4,2, 7,  1.0,'Chaos Crit',            '+1.0% Critical Strike'),
(38,31,6,4,2, 9,  2.5,'Shadowbolt Torrent',    '+2.5% Spell Power'),
(38,32,2,6,2, 4,  2.0,'Ruination Mind',        '+2.0% Intellect'),
(38,33,4,6,2, 3,  2.0,'Destruction Endurance', '+2.0% Stamina');

-- ============================================================
-- DRUID SPEC BOARDS
-- ============================================================

-- Board 39 — Balance: Celestial  (SpellPower%, Haste%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(39, 1,3,3,4, 0,  0.0,'The Celestial Path',    'Sun and moon bend to your casting.'),
(39, 2,3,1,1, 4,132.0,'Celestial Focus Mind',  '+132 Intellect'),
(39, 3,2,2,1, 9,128.0,'Starsurge Power',       '+128 Spell Power'),
(39, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(39, 5,4,2,1, 4,132.0,'Moonfire Mind',         '+132 Intellect'),
(39, 6,2,3,1, 9,128.0,'Wrath Power',           '+128 Spell Power'),
(39, 7,4,3,1, 4,132.0,'Sunfire Mind',          '+132 Intellect'),
(39, 8,2,4,1, 5,115.0,'Naturalist Spirit',     '+115 Spirit'),
(39, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(39,10,4,4,1, 9,128.0,'Starfall Power',        '+128 Spell Power'),
(39,11,3,5,1, 4,132.0,'Eclipse Mind',          '+132 Intellect'),
(39,12,1,1,0, 4, 62.0,'Balance Mind',          '+62 Intellect'),
(39,13,2,1,0, 5, 52.0,'Grove Spirit',          '+52 Spirit'),
(39,14,4,1,0, 9, 60.0,'Moonbeam Power',        '+60 Spell Power'),
(39,15,5,1,0, 3, 42.0,'Bark Endurance',        '+42 Stamina'),
(39,16,1,2,0, 9, 60.0,'Starlight Power',       '+60 Spell Power'),
(39,17,5,2,0, 4, 62.0,'Celestial Mind',        '+62 Intellect'),
(39,18,1,3,0, 4, 62.0,'Solar Beam Mind',       '+62 Intellect'),
(39,19,5,3,0, 5, 52.0,'Lunar Spirit',          '+52 Spirit'),
(39,20,1,4,0, 9, 60.0,'Typhoon Power',         '+60 Spell Power'),
(39,21,5,4,0, 4, 62.0,'Nature Insight Mind',   '+62 Intellect'),
(39,22,1,5,0, 3, 42.0,'Dream Body',            '+42 Stamina'),
(39,23,2,5,0, 9, 60.0,'Hurricane Power',       '+60 Spell Power'),
(39,24,4,5,0, 4, 62.0,'Shooting Stars Mind',   '+62 Intellect'),
(39,25,5,5,0, 9, 60.0,'Force of Nature Power', '+60 Spell Power'),
(39,26,2,0,2, 9,  2.5,'Celestial Surge',       '+2.5% Spell Power'),
(39,27,4,0,2, 8,  1.2,'Eclipse Tempo',         '+1.2% Haste'),
(39,28,0,2,2, 4,  2.0,'Moonkin Mind',          '+2.0% Intellect'),
(39,29,6,2,2, 9,  2.5,'Starsurge Torrent',     '+2.5% Spell Power'),
(39,30,0,4,2, 8,  1.2,'Starfall Speed',        '+1.2% Haste'),
(39,31,6,4,2, 9,  2.5,'Astral Surge',          '+2.5% Spell Power'),
(39,32,2,6,2, 7,  1.0,'Celestial Crit',        '+1.0% Critical Strike'),
(39,33,4,6,2, 3,  2.0,'Grove Endurance',       '+2.0% Stamina');

-- Board 40 — Feral: Primal  (Agility%, AP%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(40, 1,3,3,4, 0,  0.0,'The Primal Path',       'Tooth, claw, and predator instinct.'),
(40, 2,3,1,1, 2,138.0,'Primal Agility',        '+138 Agility'),
(40, 3,2,2,1,10,128.0,'Shred Power',           '+128 Attack Power'),
(40, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(40, 5,4,2,1, 2,138.0,'Mangle Agility',        '+138 Agility'),
(40, 6,2,3,1,10,128.0,'Rip Power',             '+128 Attack Power'),
(40, 7,4,3,1, 2,138.0,'Tiger Agility',         '+138 Agility'),
(40, 8,2,4,1, 3,112.0,'Feral Endurance',       '+112 Stamina'),
(40, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(40,10,4,4,1,10,128.0,'Ferocious Bite Power',  '+128 Attack Power'),
(40,11,3,5,1, 2,138.0,'Predatory Agility',     '+138 Agility'),
(40,12,1,1,0, 2, 65.0,'Cat Form Agility',      '+65 Agility'),
(40,13,2,1,0,10, 58.0,'Pounce Power',          '+58 Attack Power'),
(40,14,4,1,0, 2, 65.0,'Prowl Agility',         '+65 Agility'),
(40,15,5,1,0, 3, 52.0,'Bear Form Body',        '+52 Stamina'),
(40,16,1,2,0,10, 58.0,'Rake Power',            '+58 Attack Power'),
(40,17,5,2,0, 2, 65.0,'Claw Agility',          '+65 Agility'),
(40,18,1,3,0, 2, 65.0,'Tiger Fury Agility',    '+65 Agility'),
(40,19,5,3,0, 3, 52.0,'Primal Reserves',       '+52 Stamina'),
(40,20,1,4,0,10, 58.0,'Swipe Power',           '+58 Attack Power'),
(40,21,5,4,0, 2, 65.0,'Survival Instincts',    '+65 Agility'),
(40,22,1,5,0, 3, 52.0,'Wild Body',             '+52 Stamina'),
(40,23,2,5,0, 2, 65.0,'Stampede Agility',      '+65 Agility'),
(40,24,4,5,0,10, 58.0,'Skull Bash Power',      '+58 Attack Power'),
(40,25,5,5,0, 2, 65.0,'Apex Cat Agility',      '+65 Agility'),
(40,26,2,0,2, 2,  2.5,'Apex Agility',          '+2.5% Agility'),
(40,27,4,0,2,10,  2.5,'Primal Fury',           '+2.5% Attack Power'),
(40,28,0,2,2, 2,  2.5,'Feral Surge',           '+2.5% Agility'),
(40,29,6,2,2,10,  2.5,'Claw Mastery',          '+2.5% Attack Power'),
(40,30,0,4,2, 7,  1.0,'Primal Crit',           '+1.0% Critical Strike'),
(40,31,6,4,2, 2,  2.5,'Wild Agility',          '+2.5% Agility'),
(40,32,2,6,2, 8,  1.0,'Feral Tempo',           '+1.0% Haste'),
(40,33,4,6,2, 3,  2.0,'Primal Endurance',      '+2.0% Stamina');

-- Board 41 — Restoration: Verdant  (Spirit%, Stamina%)
INSERT INTO `paragon_board_nodes` (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(41, 1,3,3,4, 0,  0.0,'The Verdant Grove',     'Life flourishes wherever you walk.'),
(41, 2,3,1,1, 5,130.0,'Verdant Spirit',        '+130 Spirit'),
(41, 3,2,2,1, 9,125.0,'Rejuvenation Power',    '+125 Spell Power'),
(41, 4,3,2,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(41, 5,4,2,1, 4,122.0,'Resto Mind',            '+122 Intellect'),
(41, 6,2,3,1, 5,130.0,'Lifebloom Spirit',      '+130 Spirit'),
(41, 7,4,3,1, 9,125.0,'Wild Growth Power',     '+125 Spell Power'),
(41, 8,2,4,1, 3,118.0,'Verdant Endurance',     '+118 Stamina'),
(41, 9,3,4,3, 0,  0.0,'Glyph Socket',          'Socket a Glyph.'),
(41,10,4,4,1, 5,130.0,'Tranquility Spirit',    '+130 Spirit'),
(41,11,3,5,1, 9,125.0,'Regrowth Power',        '+125 Spell Power'),
(41,12,1,1,0, 5, 60.0,'Nourish Spirit',        '+60 Spirit'),
(41,13,2,1,0, 4, 56.0,'Grove Mind',            '+56 Intellect'),
(41,14,4,1,0, 9, 58.0,'Swiftmend Power',       '+58 Spell Power'),
(41,15,5,1,0, 3, 50.0,'Ancient Bark Body',     '+50 Stamina'),
(41,16,1,2,0, 4, 56.0,'Nature Bounty Mind',    '+56 Intellect'),
(41,17,5,2,0, 5, 60.0,'Nurturing Instinct',    '+60 Spirit'),
(41,18,1,3,0, 5, 60.0,'Dream of Cenarius',     '+60 Spirit'),
(41,19,5,3,0, 4, 56.0,'Empowered Touch Mind',  '+56 Intellect'),
(41,20,1,4,0, 9, 58.0,'Living Seed Power',     '+58 Spell Power'),
(41,21,5,4,0, 5, 60.0,'Empowered Rejuv',       '+60 Spirit'),
(41,22,1,5,0, 3, 50.0,'Overgrowth Body',       '+50 Stamina'),
(41,23,2,5,0, 9, 58.0,'Efflorescence Power',   '+58 Spell Power'),
(41,24,4,5,0, 4, 56.0,'Gift of the Earthmother','+56 Intellect'),
(41,25,5,5,0, 5, 60.0,'Verdant Keeper',        '+60 Spirit'),
(41,26,2,0,2, 5,  2.5,'Ancient Spirit',        '+2.5% Spirit'),
(41,27,4,0,2, 3,  2.5,'Verdant Constitution',  '+2.5% Stamina'),
(41,28,0,2,2, 5,  2.5,'River of Life Spirit',  '+2.5% Spirit'),
(41,29,6,2,2, 9,  2.5,'Verdant Surge',         '+2.5% Spell Power'),
(41,30,0,4,2, 8,  0.8,'Grove Tempo',           '+0.8% Haste'),
(41,31,6,4,2, 3,  2.5,'Ancient Endurance',     '+2.5% Stamina'),
(41,32,2,6,2, 7,  0.8,'Nature Crit',           '+0.8% Critical Strike'),
(41,33,4,6,2, 4,  2.0,'Verdant Mind',          '+2.0% Intellect');
