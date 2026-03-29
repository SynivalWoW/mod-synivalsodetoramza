-- ============================================================
-- mod-synival-guild-sanctuary | characters database — Dungeon Master tables
-- ============================================================
-- Run against your CHARACTERS database before starting the server.
--
-- These tables are required by the Dungeon Master subsystem
-- (originally from mod-dungeon-master by InstanceForge).
--
-- Tables created:
--   dm_player_stats           — per-player normal run statistics
--   dm_leaderboard            — fastest-clear leaderboard entries
--   dm_roguelike_player_stats — per-player roguelike run statistics
--   dm_roguelike_leaderboard  — highest-tier roguelike leaderboard entries
-- ============================================================

-- ── dm_player_stats ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `dm_player_stats` (
    `guid`                INT UNSIGNED NOT NULL DEFAULT 0
                          COMMENT 'Player GUID — matches characters.guid',
    `total_runs`          INT UNSIGNED NOT NULL DEFAULT 0,
    `completed_runs`      INT UNSIGNED NOT NULL DEFAULT 0,
    `failed_runs`         INT UNSIGNED NOT NULL DEFAULT 0,
    `total_mobs_killed`   INT UNSIGNED NOT NULL DEFAULT 0,
    `total_bosses_killed` INT UNSIGNED NOT NULL DEFAULT 0,
    `total_deaths`        INT UNSIGNED NOT NULL DEFAULT 0,
    `fastest_clear`       INT UNSIGNED NOT NULL DEFAULT 0
                          COMMENT 'Fastest clear time in seconds (0 = no clear)',
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Dungeon Master — per-player normal run statistics';

-- ── dm_leaderboard ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `dm_leaderboard` (
    `id`              INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    `guid`            INT UNSIGNED     NOT NULL DEFAULT 0,
    `char_name`       VARCHAR(32)      NOT NULL DEFAULT '',
    `map_id`          INT UNSIGNED     NOT NULL DEFAULT 0,
    `difficulty_id`   INT UNSIGNED     NOT NULL DEFAULT 0,
    `clear_time`      INT UNSIGNED     NOT NULL DEFAULT 0
                      COMMENT 'Clear time in seconds',
    `party_size`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `scaled`          TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `effective_level` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `mobs_killed`     INT UNSIGNED     NOT NULL DEFAULT 0,
    `bosses_killed`   INT UNSIGNED     NOT NULL DEFAULT 0,
    `deaths`          INT UNSIGNED     NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `idx_map_diff` (`map_id`, `difficulty_id`, `clear_time`),
    KEY `idx_clear_time` (`clear_time`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Dungeon Master — fastest-clear leaderboard entries';

-- ── dm_roguelike_player_stats ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `dm_roguelike_player_stats` (
    `guid`              INT UNSIGNED NOT NULL DEFAULT 0,
    `total_runs`        INT UNSIGNED NOT NULL DEFAULT 0,
    `completed_runs`    INT UNSIGNED NOT NULL DEFAULT 0,
    `failed_runs`       INT UNSIGNED NOT NULL DEFAULT 0,
    `highest_tier`      INT UNSIGNED NOT NULL DEFAULT 0,
    `most_floors`       INT UNSIGNED NOT NULL DEFAULT 0,
    `total_bosses`      INT UNSIGNED NOT NULL DEFAULT 0,
    `total_deaths`      INT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Dungeon Master — per-player roguelike run statistics';

-- ── dm_roguelike_leaderboard ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `dm_roguelike_leaderboard` (
    `id`              INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    `guid`            INT UNSIGNED     NOT NULL DEFAULT 0,
    `char_name`       VARCHAR(32)      NOT NULL DEFAULT '',
    `highest_tier`    INT UNSIGNED     NOT NULL DEFAULT 0,
    `floors_cleared`  INT UNSIGNED     NOT NULL DEFAULT 0,
    `party_size`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `effective_level` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `total_bosses`    INT UNSIGNED     NOT NULL DEFAULT 0,
    `total_deaths`    INT UNSIGNED     NOT NULL DEFAULT 0,
    `run_timestamp`   INT UNSIGNED     NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `idx_tier`   (`highest_tier` DESC),
    KEY `idx_floors` (`floors_cleared` DESC)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Dungeon Master — roguelike highest-tier leaderboard entries';
