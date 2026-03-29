-- ============================================================
-- mod-synival-paragon | Cache of Synival's Treasures patch
-- Run against your WORLD database.
--
-- This patch updates item entry 99200 so that it:
--   1. Becomes right-clickable (spelltrigger_1 = 0 = On Use,
--      spellcharges_1 = 0 = unlimited until destroyed by script)
--   2. Registers the C++ ItemScript 'item_cache_of_synival'
--      which handles the actual reward logic server-side
--   3. Updates the description to reflect the new contents
--
-- Display ID, quality, bonding, and all stat columns are left
-- unchanged — update those from your own item_template.sql once
-- you have confirmed the entry exists.
--
-- Schema reference: https://www.azerothcore.org/wiki/item_template
-- ============================================================

UPDATE `item_template`
SET
    -- Make the item usable: spelltrigger_1 = 0 means "On Use"
    -- spellcharges_1 = 0 means unlimited charges (script destroys the item)
    -- spellid_1 = 0: the actual reward logic lives in the C++ ItemScript,
    --   not in a spell — so we leave the spell ID at 0 and let the script fire
    `spelltrigger_1`          = 0,
    `spellcharges_1`          = 0,
    `spellid_1`               = 0,
    `spellppmRate_1`          = 0.0,
    `spellcooldown_1`         = -1,
    `spellcategory_1`         = 0,
    `spellcategorycooldown_1` = -1,

    -- Register the C++ ItemScript
    `ScriptName` = 'item_cache_of_synival',

    -- Updated description visible in the item tooltip
    `description` = 'Right-click to open. Contains Paragon Shards and a random piece of equipment. Awarded once per day on login.'

WHERE `entry` = 99200;
