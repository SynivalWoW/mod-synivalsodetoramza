-- ============================================================
-- mod-coffingquest-oldworld-flying
-- World Flight Mastery — Grant to existing characters
-- Run against: acore_characters
-- ============================================================
--
-- Grants spell 200010 (World Flight Mastery) to all characters
-- who already possess an Expert Riding skill (spell 34090) or
-- better — meaning they have the physical capability to fly,
-- just not Blizzard's permission to do so outside Outland.
--
-- This targets characters with any of the following riding
-- skill spells, which represent the full spectrum of flying
-- mount capability in WotLK 3.3.5a:
--
--   34090 — Expert Riding (60% flying, Outland unlock)
--   34091 — Artisan Riding (280% flying)
--   90265 — Master Riding (310% flying)
--   54197 — Cold Weather Flying (Northrend unlock, already implies flying skill)
--
-- Characters who can only ride ground mounts are intentionally
-- excluded — granting airborne permission to someone who has
-- never left the ground is a metaphor for several things,
-- none of which belong in a flight module.
--
-- Safe to re-run: INSERT IGNORE prevents duplicate rows.
-- ============================================================

USE `acore_characters`;

-- Grant World Flight Mastery to all characters with flying riding skill
INSERT IGNORE INTO `character_spell` (`guid`, `spell`, `specMask`)
SELECT DISTINCT cs.`guid`, 200010, 255
FROM `character_spell` cs
WHERE cs.`spell` IN (34090, 34091, 90265, 54197)
  AND cs.`guid` NOT IN (
      SELECT `guid` FROM `character_spell` WHERE `spell` = 200010
  );

-- ============================================================
-- Optional: grant to ALL characters unconditionally.
-- Comment out the block above and uncomment this if
-- OldWorldFlying.AllPlayersFly = 1 in the conf, or if you
-- simply believe everyone deserves to fly and Blizzard was wrong.
-- ============================================================
-- INSERT IGNORE INTO `character_spell` (`guid`, `spell`, `specMask`)
-- SELECT `guid`, 200010, 255
-- FROM `characters`
-- WHERE `guid` NOT IN (
--     SELECT `guid` FROM `character_spell` WHERE `spell` = 200010
-- );

-- Verify: count of characters granted the spell
SELECT COUNT(*) AS `characters_granted_world_flight_mastery`
FROM `character_spell`
WHERE `spell` = 200010;
