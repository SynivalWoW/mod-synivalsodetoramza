-- ============================================================
-- synparagon_config.sql
-- Run against acpb_world ONCE to create the config table.
-- C++ OnBeforeConfigLoad populates it automatically on every
-- server start and reload — you never need to edit this table
-- directly. The Lua gossip script reads it to stay in sync
-- with the active .conf file without hardcoded values.
-- ============================================================
USE acpb_world;

CREATE TABLE IF NOT EXISTS `synparagon_config` (
    `cfg_key`   VARCHAR(64)  NOT NULL,
    `cfg_value` VARCHAR(128) NOT NULL DEFAULT '',
    PRIMARY KEY (`cfg_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Synival Paragon — live config values written by C++ on startup';

-- Seed with defaults so the table is immediately usable even before
-- the first server start writes to it. C++ will REPLACE these on startup.
INSERT IGNORE INTO `synparagon_config` (`cfg_key`, `cfg_value`) VALUES
('BaseCap',              '200'),
('ExtendedCap',          '2000'),
('MaxPrestige',          '10'),
('StatBonusPerLevel',    '0.5000'),
('StatBonusCap',         '100.0'),
('MarkBonusPercent',     '15.0'),
('XPPerLevel',           '1500000'),
('PrestigeBoardPtBonus', '5'),
('BoardPointKillChance', '5'),
('HiddenAffixChance',    '15'),
('PrestigeAchievId',     '2139'),
('ItemCacheEntry',       '99200');

SELECT 'synparagon_config table created and seeded.' AS Status;
