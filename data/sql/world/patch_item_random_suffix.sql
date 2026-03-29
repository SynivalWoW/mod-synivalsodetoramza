-- ============================================================
-- patch_item_random_suffix.sql
-- Server-side companion to patch_item_random_suffix.py
-- Run against acpb_world.
--
-- Registers custom tier suffix IDs in item_random_suffix_dbc
-- so AzerothCore validates them correctly when reading item
-- instance data. Without these rows AC logs warnings about
-- unknown suffix IDs on player login.
--
-- item_random_suffix_dbc mirrors ItemRandomSuffix.dbc.
-- Column layout (21 fields, standard AC world DB schema):
--   ID, Name_lang_enUS, Name_lang_koKR, Name_lang_frFR,
--   Name_lang_deDE, Name_lang_zhCN, Name_lang_zhTW,
--   Name_lang_esES, Name_lang_esMX, Name_lang_ruRU,
--   Name_lang_Mask, InternalName,
--   Enchantment_1..5  (0 = no enchant effect),
--   AllocationPct_1..5 (0 = no stat roll)
--
-- All enchant/allocation fields are 0 — these are purely
-- cosmetic suffixes. Stats are applied server-side by
-- mod_synival_loot.cpp independently of this suffix system.
-- ============================================================
USE acpb_world;

INSERT IGNORE INTO `item_random_suffix_dbc`
    (`ID`,
     `Name_lang_enUS`,
     `Name_lang_koKR`, `Name_lang_frFR`, `Name_lang_deDE`,
     `Name_lang_zhCN`, `Name_lang_zhTW`, `Name_lang_esES`,
     `Name_lang_esMX`, `Name_lang_ruRU`,
     `Name_lang_Mask`,
     `InternalName`,
     `Enchantment_1`, `Enchantment_2`, `Enchantment_3`,
     `Enchantment_4`, `Enchantment_5`,
     `AllocationPct_1`, `AllocationPct_2`, `AllocationPct_3`,
     `AllocationPct_4`, `AllocationPct_5`)
VALUES
(9901, 'SynHeroic',        '', '', '', '', '', '', '', '', 4, 'SynHeroic',        0,0,0,0,0, 0,0,0,0,0),
(9902, 'Mythical',         '', '', '', '', '', '', '', '', 4, 'Mythical',         0,0,0,0,0, 0,0,0,0,0),
(9903, 'Ascended',         '', '', '', '', '', '', '', '', 4, 'Ascended',         0,0,0,0,0, 0,0,0,0,0),
(9904, 'Synival''s Chosen','', '', '', '', '', '', '', '', 4, 'Synival''s Chosen',0,0,0,0,0, 0,0,0,0,0);

SELECT CONCAT('Inserted ', ROW_COUNT(),
    ' rows into item_random_suffix_dbc (0 = already existed).') AS Status;
