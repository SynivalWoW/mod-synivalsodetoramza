-- ============================================================
-- mod-synival-paragon | characters database — BOARD SYSTEM
-- ============================================================
-- Compatible with MySQL 8.x and HeidiSQL.
-- All three tables use CREATE TABLE IF NOT EXISTS.
-- Safe to run on a fresh install or an existing one.
--
-- EXISTING INSTALL NOTE:
--   The ALTER TABLE at the bottom adds board_points to an
--   already-existing character_paragon table.
--   If you get Error 1060 "Duplicate column name 'board_points'"
--   it means the column is already there — safe to ignore.
-- ============================================================


-- ── 1. character_paragon ────────────────────────────────────
-- Full table definition including board_points.
-- On a fresh install this creates the table complete.
-- On an existing install IF NOT EXISTS skips it entirely,
-- and the ALTER TABLE at the bottom handles the new column.
CREATE TABLE IF NOT EXISTS `character_paragon` (
    `guid`                    INT     UNSIGNED NOT NULL DEFAULT 0
                              COMMENT 'Player GUID — matches characters.guid',
    `paragon_level`           INT     UNSIGNED NOT NULL DEFAULT 0
                              COMMENT 'Current Paragon Level (0 – ExtendedCap)',
    `paragon_xp`              INT     UNSIGNED NOT NULL DEFAULT 0
                              COMMENT 'XP accumulated toward the next Paragon Level',
    `prestige_count`          INT     UNSIGNED NOT NULL DEFAULT 0
                              COMMENT 'Number of completed Prestiges (0 – MaxPrestige)',
    `last_cache_day`          INT     UNSIGNED NOT NULL DEFAULT 0
                              COMMENT 'Unix day number of last daily cache award',
    `mark_used`               TINYINT UNSIGNED NOT NULL DEFAULT 0
                              COMMENT '1 = Mark of the Ascended applied; 0 = not yet used',
    `board_points`            INT     UNSIGNED NOT NULL DEFAULT 0
                              COMMENT 'Unspent Paragon Board points',
    `paragon_shards`          INT     UNSIGNED NOT NULL DEFAULT 0
                              COMMENT 'Current Paragon Shard currency balance',
    `last_shard_purchase_day` INT     UNSIGNED NOT NULL DEFAULT 0
                              COMMENT 'Unix day of last Kadala shard bundle purchase (24hr cooldown)',
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Synival Paragon System — per-character progression data';


-- ── 2. character_paragon_nodes ──────────────────────────────
-- One row per (player, board, node) that has been unlocked.
CREATE TABLE IF NOT EXISTS `character_paragon_nodes` (
    `guid`     INT      UNSIGNED NOT NULL DEFAULT 0
               COMMENT 'Player GUID — matches characters.guid',
    `board_id` TINYINT  UNSIGNED NOT NULL DEFAULT 0
               COMMENT 'Board ID from paragon_boards',
    `node_id`  SMALLINT UNSIGNED NOT NULL DEFAULT 0
               COMMENT 'Node ID from paragon_board_nodes',
    PRIMARY KEY (`guid`, `board_id`, `node_id`),
    KEY `idx_cpn_guid_board` (`guid`, `board_id`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Synival Paragon Board — per-character unlocked node records';


-- ── 3. character_paragon_glyphs ─────────────────────────────
-- One row per socket node that has a glyph slotted in.
-- Row is deleted on glyph removal; item is returned to bags by C++.
CREATE TABLE IF NOT EXISTS `character_paragon_glyphs` (
    `guid`     INT      UNSIGNED NOT NULL DEFAULT 0
               COMMENT 'Player GUID',
    `board_id` TINYINT  UNSIGNED NOT NULL DEFAULT 0
               COMMENT 'Board ID from paragon_boards',
    `node_id`  SMALLINT UNSIGNED NOT NULL DEFAULT 0
               COMMENT 'Socket node ID (must be NODE_SOCKET type)',
    `glyph_id` SMALLINT UNSIGNED NOT NULL DEFAULT 0
               COMMENT 'Glyph ID from paragon_glyphs',
    PRIMARY KEY (`guid`, `board_id`, `node_id`),
    KEY `idx_cpg_guid_board` (`guid`, `board_id`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Synival Paragon Board — per-character socketed glyph records';


-- ── 4. Existing install migration ───────────────────────────
-- Only needed if character_paragon already existed before this
-- file was run. Adds the board_points column to the old table.
-- If Error 1060 "Duplicate column name" appears, ignore it —
-- it means the column is already present from a previous run.
ALTER TABLE `character_paragon`
    ADD COLUMN IF NOT EXISTS `board_points` INT UNSIGNED NOT NULL DEFAULT 0
    COMMENT 'Unspent Paragon Board points available for node unlocks';

-- ── 5. Existing install migration — Paragon Shard columns ───────────────────
-- These two ALTER statements add the shard fields to an existing installation.
-- Error 1060 "Duplicate column name" = column already exists, safe to ignore.
ALTER TABLE `character_paragon`
    ADD COLUMN IF NOT EXISTS `paragon_shards` INT UNSIGNED NOT NULL DEFAULT 0
    COMMENT 'Current Paragon Shard currency balance';

ALTER TABLE `character_paragon`
    ADD COLUMN IF NOT EXISTS `last_shard_purchase_day` INT UNSIGNED NOT NULL DEFAULT 0
    COMMENT 'Unix day of last Kadala shard bundle purchase (24hr per-player cooldown)';
