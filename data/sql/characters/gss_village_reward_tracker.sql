-- ============================================================
-- mod-synival-ode-to-ramza | characters database
-- Guild Village Periodic Reward Tracker
-- ============================================================
-- Run against acore_characters before starting the server.
--
-- Tracks the last time each character received a village
-- periodic reward, preventing players from getting backdated
-- payouts for time spent offline. One row per character.
--
-- Safe to re-run (CREATE TABLE IF NOT EXISTS).
-- ============================================================

CREATE TABLE IF NOT EXISTS `character_gv_reward_tracker` (
    `guid`             INT UNSIGNED  NOT NULL
                       COMMENT 'Character GUID — matches characters.guid',
    `last_reward_time` INT UNSIGNED  NOT NULL DEFAULT 0
                       COMMENT 'UNIX timestamp of the last reward distribution',
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Synival Ode to Ramza — per-character village reward timestamps';
