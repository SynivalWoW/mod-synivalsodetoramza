-- ============================================================
-- Synival's Chosen — Reagent & Stacking Limit Removal
-- ============================================================
-- Run against your WORLD database.
-- Removes reagent requirements and stacking limitations for
-- all class-specific group buff spells (Arcane Brilliance,
-- Prayer of Fortitude, Gift of the Wild, Blessings, etc.)
--
-- Method: Sets reagent item entries to 0 in spell_template
-- for all affected spell IDs. Also removes group-size limits
-- by zeroing out the stacking check fields.
--
-- Safe to re-run (uses UPDATE not INSERT).
-- ============================================================

-- ── Warrior ──────────────────────────────────────────────────────────────────
-- Battle Shout (all ranks) — remove reagent
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (6673, 5242, 6192, 11549, 11550, 11551, 25289, 47436);

-- Commanding Shout (all ranks) — remove reagent
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (5765, 6190, 11552, 11553, 25202, 47440);

-- ── Paladin ───────────────────────────────────────────────────────────────────
-- Blessing of Kings / Greater Blessing of Kings
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (20217, 20218, 20219, 20220, 20221, 25898);

-- Blessing of Might / Greater Blessing of Might (all ranks)
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (19740, 19834, 19835, 19836, 19837, 19838, 25291, 48932, 48934);

-- Blessing of Wisdom / Greater Blessing of Wisdom (all ranks)
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (20911, 20912, 20913, 20914, 20915, 27140, 33330, 48935, 48936);

-- Blessing of Sanctuary / Greater Blessing of Sanctuary
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (20914, 25899);

-- ── Druid ─────────────────────────────────────────────────────────────────────
-- Mark of the Wild (all ranks)
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (1126, 5232, 6756, 5234, 8907, 9884, 9885, 26990, 48469);

-- Gift of the Wild (all ranks) — group buff, uses Ironwood Seed reagent
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (21849, 21850, 26991, 48470);

-- ── Priest ────────────────────────────────────────────────────────────────────
-- Power Word: Fortitude (all ranks)
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (1243, 1244, 1245, 2791, 10937, 10938, 25389, 48161, 48162);

-- Prayer of Fortitude (all ranks) — uses Symbol of Hope
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (21562, 21564, 25392, 48162);

-- Prayer of Spirit / Prayer of Shadow Protection — uses Symbol of Hope
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (14752, 14818, 14819, 27841, 48073, 48074, 32999, 39374);

-- Divine Spirit (all ranks)
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (14752, 14818, 14819, 27841, 25312);

-- ── Mage ──────────────────────────────────────────────────────────────────────
-- Arcane Intellect (all ranks)
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (1459, 1460, 1461, 10156, 10157, 27126, 42995);

-- Arcane Brilliance (all ranks) — uses Arcane Powder
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (23028, 27127, 43002);

-- ── Death Knight ──────────────────────────────────────────────────────────────
-- Horn of Winter (all ranks)
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (57330, 57623);

-- ── Shaman ────────────────────────────────────────────────────────────────────
-- Strength of Earth Totem (all ranks)
UPDATE `spell_template` SET `Reagent_1` = 0, `ReagentCount_1` = 0
WHERE `entry` IN (8076, 8162, 8163, 10442, 25361, 25528, 57621);

-- ── Remove group-size stacking limit on all group buffs ───────────────────────
-- In spell_template, StackAmount controls how many stacks are allowed.
-- Setting it to 0 removes the per-player stack limit entirely.
-- Targets only the group buff variants (Greater/Prayer/Gift/Arcane Brilliance).
UPDATE `spell_template` SET `StackAmount` = 0
WHERE `entry` IN (
    -- Greater Blessings (Paladin)
    25898, 48934, 25899, 48936,
    -- Prayer buffs (Priest)
    48162, 48074, 39374,
    -- Gift of the Wild (Druid)
    48470, 26991,
    -- Arcane Brilliance (Mage)
    43002, 27127,
    -- Horn of Winter (DK)
    57623,
    -- Commanding Shout (Warrior)
    47440,
    -- Battle Shout (Warrior)
    47436
);

SELECT 'Reagent removal and stacking limit patch applied.' AS Status;
