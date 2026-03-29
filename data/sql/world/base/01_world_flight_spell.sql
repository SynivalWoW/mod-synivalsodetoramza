-- ============================================================
-- mod-coffingquest-oldworld-flying
-- World Flight Mastery — spell_dbc entry
-- Run against: acore_world
-- ============================================================
--
-- Inserts spell ID 200010 "World Flight Mastery" as a server-side
-- learnable spell. This mirrors Cold Weather Flying (54197) in
-- purpose but applies to Eastern Kingdoms and Kalimdor.
--
-- The spell has no functional aura effect of its own — the module's
-- C++ hooks detect its presence via HasSpell() and apply the
-- MOVEMENTFLAG_CAN_FLY flag directly. The spell exists purely
-- as a learnable permission token, the same architectural pattern
-- Blizzard used for Cold Weather Flying.
--
-- Fields cloned from Cold Weather Flying (54197) where applicable.
-- ============================================================

DELETE FROM `spell_dbc` WHERE `Id` = 200010;
INSERT INTO `spell_dbc` (
    `Id`,
    `Dispel`,
    `Mechanic`,
    `Attributes`,
    `AttributesEx`,
    `AttributesEx2`,
    `AttributesEx3`,
    `AttributesEx4`,
    `AttributesEx5`,
    `AttributesEx6`,
    `AttributesEx7`,
    `Stances`,
    `StancesNot`,
    `Targets`,
    `CastingTimeIndex`,
    `AuraInterruptFlags`,
    `ProcFlags`,
    `ProcChance`,
    `ProcCharges`,
    `MaxLevel`,
    `BaseLevel`,
    `SpellLevel`,
    `DurationIndex`,
    `RangeIndex`,
    `StackAmount`,
    `SpellIconID`,
    `ActiveIconID`,
    `SpellName_Lang_enUS`,
    `SpellName_Lang_Mask`,
    `Description_Lang_enUS`,
    `Description_Lang_Mask`,
    `AuraDescription_Lang_enUS`,
    `AuraDescription_Lang_Mask`,
    `SchoolMask`,
    `runeCostID`,
    `Effect_1`,
    `EffectDieSides_1`,
    `EffectRealPointsPerLevel_1`,
    `EffectBasePoints_1`,
    `EffectMechanic_1`,
    `EffectImplicitTargetA_1`,
    `EffectImplicitTargetB_1`,
    `EffectApplyAuraName_1`,
    `EffectAmplitude_1`,
    `EffectMultipleValue_1`,
    `EffectMiscValue_1`,
    `EffectMiscValueB_1`,
    `EffectTriggerSpell_1`,
    `EffectPointsPerComboPoint_1`
) VALUES (
    200010,         -- Id
    0,              -- Dispel: none
    0,              -- Mechanic: none
    0x00000080,     -- Attributes: SPELL_ATTR0_NOT_SHAPESHIFT (passive-style)
    0x00000200,     -- AttributesEx: SPELL_ATTR1_NOT_BREAK_STEALTH
    0x00000000,     -- AttributesEx2
    0x00000000,     -- AttributesEx3
    0x00000000,     -- AttributesEx4
    0x00000000,     -- AttributesEx5
    0x00000000,     -- AttributesEx6
    0x00000000,     -- AttributesEx7
    0,              -- Stances: all stances
    0,              -- StancesNot
    0,              -- Targets: self
    1,              -- CastingTimeIndex: instant
    0,              -- AuraInterruptFlags
    0,              -- ProcFlags
    101,            -- ProcChance: always (101 = guaranteed)
    0,              -- ProcCharges
    0,              -- MaxLevel: no cap
    0,              -- BaseLevel
    0,              -- SpellLevel
    21,             -- DurationIndex: -1 (permanent / passive)
    1,              -- RangeIndex: self
    0,              -- StackAmount
    2628,           -- SpellIconID: riding skill icon (same as Cold Weather Flying)
    2628,           -- ActiveIconID
    'World Flight Mastery',         -- SpellName_Lang_enUS
    16712190,                        -- SpellName_Lang_Mask (all locales)
    'Allows the use of flying mounts in Eastern Kingdoms and Kalimdor. Because some rules exist to be questioned.', -- Description_Lang_enUS
    16712190,                        -- Description_Lang_Mask
    '',             -- AuraDescription_Lang_enUS
    0,              -- AuraDescription_Lang_Mask
    1,              -- SchoolMask: physical
    0,              -- runeCostID
    36,             -- Effect_1: SPELL_EFFECT_APPLY_AURA
    0,              -- EffectDieSides_1
    0,              -- EffectRealPointsPerLevel_1
    0,              -- EffectBasePoints_1
    0,              -- EffectMechanic_1
    1,              -- EffectImplicitTargetA_1: TARGET_UNIT_CASTER
    0,              -- EffectImplicitTargetB_1
    79,             -- EffectApplyAuraName_1: SPELL_AURA_FEATHER_FALL (harmless passive marker)
    0,              -- EffectAmplitude_1
    0,              -- EffectMultipleValue_1
    0,              -- EffectMiscValue_1
    0,              -- EffectMiscValueB_1
    0,              -- EffectTriggerSpell_1
    0               -- EffectPointsPerComboPoint_1
);

-- ============================================================
-- Learnable spell entry — makes the spell visible in the
-- player's spellbook when learned. Without this row the spell
-- works mechanically but is invisible in the UI, which is
-- philosophically unsatisfying even if functionally fine.
-- ============================================================
DELETE FROM `spell_learn_spell` WHERE `entry` = 200010;
-- (No automatic learn chain — the spell is granted manually
--  via NPC, item, or direct DB grant.)

-- Confirm insertion
SELECT Id, SpellName_Lang_enUS, Description_Lang_enUS
FROM `spell_dbc`
WHERE Id = 200010;
