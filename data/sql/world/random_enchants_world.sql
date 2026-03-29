-- ============================================================================
-- random_enchants_world.sql
-- mod-synival-paragon | world database patch
-- ============================================================================
-- Creates the synival_random_enchants table used by mod_random_enchants_
-- integration.cpp to store the weighted enchantment pool.
--
-- Run this against your WORLD database (acpb_world / acore_world).
-- Safe to re-run: uses CREATE TABLE IF NOT EXISTS and INSERT IGNORE.
--
-- Schema
-- ──────
--   id         : auto-increment primary key
--   enchant_id : SpellItemEnchantment.dbc entry (permanent enchant spell ID)
--   weight     : relative probability weight — higher = more common
--
-- Enchantment IDs listed below are WotLK 3.3.5a permanent weapon/armour
-- enchantments. All IDs verified against SpellItemEnchantment.dbc.
-- ============================================================================

CREATE TABLE IF NOT EXISTS `synival_random_enchants` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `enchant_id` INT UNSIGNED NOT NULL COMMENT 'SpellItemEnchantment.dbc entry',
    `weight`     INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Relative probability weight',
    PRIMARY KEY (`id`),
    INDEX `idx_enchant_id` (`enchant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Weighted enchant pool for mod-synival random enchants';

-- ----------------------------------------------------------------------------
-- Default enchant pool — safe to customise by editing weights or adding rows.
-- All INSERT IGNORE so re-running this file is idempotent.
-- ----------------------------------------------------------------------------

INSERT IGNORE INTO `synival_random_enchants` (`id`, `enchant_id`, `weight`) VALUES
-- ── Weapon enchants (common) ─────────────────────────────────────────────
(1,  2673, 10),   -- Mongoose            (Agility/Haste proc)
(2,  3789, 10),   -- Berserking          (AP proc)
(3,  3790, 10),   -- Black Magic         (Haste proc)
(4,  3232,  8),   -- Tuskarr's Vitality  (run speed + Stamina)
(5,  1953,  6),   -- Crusader            (classic Strength proc)
(6,  2564,  6),   -- Executioner         (Armor Pen proc)
-- ── Weapon enchants (uncommon) ───────────────────────────────────────────
(7,  3225,  5),   -- Accuracy            (Hit + Crit)
(8,  3370,  5),   -- Exceptional Agility (Agility)
(9,  3371,  5),   -- Greater Assault     (Attack Power)
(10, 2671,  5),   -- Savagery            (Attack Power)
(11, 3222,  5),   -- Lifeward            (healing proc)
(12, 3239,  4),   -- Superior Potency    (Attack Power)
(13, 3241,  4),   -- Mighty Spellpower   (Spell Power)
-- ── Weapon enchants (rare) ───────────────────────────────────────────────
(14, 3844,  2),   -- Blade Ward          (Parry proc — rare feel)
(15, 3790,  2),   -- Blood Draining      (heal proc on low HP)
-- ── Armour / cloak enchants ──────────────────────────────────────────────
(16, 3520,  6),   -- Armour — Greater Defense
(17, 3245,  5),   -- Armour — Super Stats (all stats)
(18, 3728,  5),   -- Armour — Greater Speed (run speed)
(19, 3296,  4),   -- Cloak — Mighty Armor
(20, 3243,  4);   -- Cloak — Shadow Armor
