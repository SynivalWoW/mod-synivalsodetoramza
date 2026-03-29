-- ============================================================
-- mod-synival-guild-sanctuary | characters database
-- ============================================================
-- Run against your CHARACTERS database before starting the server.
--
-- Creates two tables:
--   gss_guild_dungeon_stats — aggregate per-guild dungeon statistics
--   gss_guild_dungeon_log   — per-run log (capped at 50 rows per guild)
--
-- Both tables are guild-scoped (keyed on guild_id from the guild table
-- in the characters database).
-- ============================================================

-- ── gss_guild_dungeon_stats ────────────────────────────────────────────────
-- One row per guild. Created by INSERT IGNORE in C++ on first run.
CREATE TABLE IF NOT EXISTS `gss_guild_dungeon_stats` (
    `id`                  INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    `guild_id`            INT UNSIGNED     NOT NULL DEFAULT 0
                          COMMENT 'Guild ID — matches guild.guildid in characters DB',
    `total_runs`          INT UNSIGNED     NOT NULL DEFAULT 0
                          COMMENT 'Total dungeon runs started via the Vault',
    `completed_runs`      INT UNSIGNED     NOT NULL DEFAULT 0
                          COMMENT 'Runs in which the final boss was defeated',
    `failed_runs`         INT UNSIGNED     NOT NULL DEFAULT 0
                          COMMENT 'Runs that ended in failure or abandonment',
    `fastest_clear`       INT UNSIGNED     NOT NULL DEFAULT 0
                          COMMENT 'Fastest successful clear time in seconds (0 = none yet)',
    `total_bosses_killed` INT UNSIGNED     NOT NULL DEFAULT 0
                          COMMENT 'Total boss kills across all runs',
    `total_deaths`        INT UNSIGNED     NOT NULL DEFAULT 0
                          COMMENT 'Total player deaths across all runs',
    `last_run`            INT UNSIGNED     NOT NULL DEFAULT 0
                          COMMENT 'UNIX timestamp of the most recent run',
    PRIMARY KEY (`id`),
    UNIQUE KEY  `uq_gss_guild`      (`guild_id`),
    KEY         `idx_last_run`      (`last_run`),
    KEY         `idx_fastest_clear` (`fastest_clear`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Synival Guild Sanctuary — per-guild dungeon aggregate stats';

-- ── gss_guild_dungeon_log ─────────────────────────────────────────────────
-- Rolling log: newest 50 entries per guild are kept.
-- The C++ trim query fires after every INSERT.
CREATE TABLE IF NOT EXISTS `gss_guild_dungeon_log` (
    `id`              INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    `guild_id`        INT UNSIGNED     NOT NULL DEFAULT 0
                      COMMENT 'Guild ID',
    `map_id`          INT UNSIGNED     NOT NULL DEFAULT 0
                      COMMENT 'Dungeon map ID (matches DungeonInfo.MapId)',
    `difficulty_id`   INT UNSIGNED     NOT NULL DEFAULT 0
                      COMMENT 'DifficultyTier.Id used for this run',
    `completed`       TINYINT UNSIGNED NOT NULL DEFAULT 0
                      COMMENT '1 = successful clear; 0 = failed/abandoned',
    `clear_time_secs` INT UNSIGNED     NOT NULL DEFAULT 0
                      COMMENT 'Wall-clock seconds from session start to end (0 if failed)',
    `bosses_killed`   INT UNSIGNED     NOT NULL DEFAULT 0
                      COMMENT 'Boss kills in this run',
    `deaths`          INT UNSIGNED     NOT NULL DEFAULT 0
                      COMMENT 'Total player deaths in this run',
    `run_timestamp`   INT UNSIGNED     NOT NULL DEFAULT 0
                      COMMENT 'UNIX timestamp when the run ended',
    PRIMARY KEY (`id`),
    KEY `idx_guild_ts`  (`guild_id`, `run_timestamp`),
    KEY `idx_guild_done` (`guild_id`, `completed`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Synival Guild Sanctuary — per-run log (last 50 per guild)';
