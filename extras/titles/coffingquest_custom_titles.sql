-- ============================================================
-- CoffingQuest Custom Titles — v4
-- 25 titles: 2 server-specific + 23 WoW-lore-recontextualized
-- Entry IDs: 178–202
--
-- Schema: acore_world.chartitles_dbc (37 columns)
-- Verified against HeidiSQL column inspector.
--
-- Columns populated:
--   ID            — title entry ID
--   Name_Lang_enUS — male title string (%s = character name)
--   Name_Lang_Mask — locale mask (16712190 = enUS active)
--   Name1_Lang_enUS — female title string
--   Name1_Lang_Mask — locale mask (16712190 = enUS active)
--   Condition_ID   — 0 (no condition)
--   Mask_ID        — matches ID (standard AzerothCore pattern)
--   All other language columns — empty string (not used)
--
-- Grant in-game: .title add <ID>
-- ============================================================

-- Wipe any previous attempts that were formatted incorrectly.
DELETE FROM `acore_world`.`chartitles_dbc` WHERE `ID` BETWEEN 178 AND 202;

INSERT INTO `acore_world`.`chartitles_dbc`
    (`ID`, `Condition_ID`,
     `Name_Lang_enUS`,  `Name_Lang_enGB`,  `Name_Lang_koKR`,  `Name_Lang_frFR`,
     `Name_Lang_deDE`,  `Name_Lang_enCN`,  `Name_Lang_zhCN`,  `Name_Lang_enTW`,
     `Name_Lang_zhTW`,  `Name_Lang_esES`,  `Name_Lang_esMX`,  `Name_Lang_ruRU`,
     `Name_Lang_ptPT`,  `Name_Lang_ptBR`,  `Name_Lang_itIT`,  `Name_Lang_Unk`,
     `Name_Lang_Mask`,
     `Name1_Lang_enUS`, `Name1_Lang_enGB`, `Name1_Lang_koKR`, `Name1_Lang_frFR`,
     `Name1_Lang_deDE`, `Name1_Lang_enCN`, `Name1_Lang_zhCN`, `Name1_Lang_enTW`,
     `Name1_Lang_zhTW`, `Name1_Lang_esES`, `Name1_Lang_esMX`, `Name1_Lang_ruRU`,
     `Name1_Lang_ptPT`, `Name1_Lang_ptBR`, `Name1_Lang_itIT`, `Name1_Lang_Unk`,
     `Name1_Lang_Mask`,
     `Mask_ID`)
VALUES

-- ============================================================
-- CoffingQuest Server (IDs 178–179)
-- ============================================================

(178, 0,
 '%s, Founder of CoffingQuest', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s, Founder of CoffingQuest', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 178),

(179, 0,
 '%s, Contributor to CoffingQuest', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s, Contributor to CoffingQuest', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 179),

-- ============================================================
-- Lovecraft → Old Gods / Void / Black Empire (IDs 180–184)
-- ============================================================

(180, 0,
 '%s, Dreamer of the Void', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s, Dreamer of the Void', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 180),

(181, 0,
 'Herald of the Black Empire %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 'Herald of the Black Empire %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 181),

(182, 0,
 '%s the Unknowable', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s the Unknowable', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 182),

(183, 0,
 '%s, Keeper of Forbidden Lore', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s, Keeper of Forbidden Lore', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 183),

(184, 0,
 'Twilight\'s Hammer %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 'Twilight\'s Hammer %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 184),

-- ============================================================
-- Diablo → Burning Legion / Naaru / Eternal Conflict (IDs 185–190)
-- ============================================================

(185, 0,
 '%s, Scion of the Titan-Forged', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s, Scion of the Titan-Forged', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 185),

(186, 0,
 'Lord of the Burning Legion %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 'Lady of the Burning Legion %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 186),

(187, 0,
 '%s, Breaker of the Legion\'s Chain', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s, Breaker of the Legion\'s Chain', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 187),

(188, 0,
 'Kirin Tor Archmage %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 'Kirin Tor Archmage %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 188),

(189, 0,
 '%s, Veteran of the War of Ancients', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s, Veteran of the War of Ancients', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 189),

(190, 0,
 'Champion of Karazhan %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 'Champion of Karazhan %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 190),

-- ============================================================
-- Warcraft Lore (IDs 191–196)
-- ============================================================

(191, 0,
 '%s, Keeper of the Dark Portal', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s, Keeper of the Dark Portal', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 191),

(192, 0,
 'Warchief %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 'Warchief %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 192),

(193, 0,
 '%s, Chosen of the Aspects', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s, Chosen of the Aspects', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 193),

(194, 0,
 'Arch-Druid %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 'Arch-Druid %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 194),

(195, 0,
 '%s, Guardian of Tirisfal', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s, Guardian of Tirisfal', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 195),

(196, 0,
 '%s, Bane of the Black Empire', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s, Bane of the Black Empire', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 196),

-- ============================================================
-- Path of Exile → Exiles / Corruption / Ascendancy (IDs 197–202)
-- ============================================================

(197, 0,
 '%s the Forsaken', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s the Forsaken', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 197),

(198, 0,
 '%s the Deathless', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s the Deathless', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 198),

(199, 0,
 '%s, Liberator of Outland', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s, Liberator of Outland', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 199),

(200, 0,
 'Fel-Sworn %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 'Fel-Sworn %s', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 200),

(201, 0,
 '%s, the Nightmare\'s End', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s, the Nightmare\'s End', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 201),

(202, 0,
 '%s of the Highmountain', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 '%s of the Highmountain', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
 16712190,
 202);

-- ============================================================
-- Quick reference
-- ============================================================
--   178  | %s, Founder of CoffingQuest
--   179  | %s, Contributor to CoffingQuest
--   180  | %s, Dreamer of the Void
--   181  | Herald of the Black Empire %s
--   182  | %s the Unknowable
--   183  | %s, Keeper of Forbidden Lore
--   184  | Twilight's Hammer %s
--   185  | %s, Scion of the Titan-Forged
--   186  | Lord/Lady of the Burning Legion %s
--   187  | %s, Breaker of the Legion's Chain
--   188  | Kirin Tor Archmage %s
--   189  | %s, Veteran of the War of Ancients
--   190  | Champion of Karazhan %s
--   191  | %s, Keeper of the Dark Portal
--   192  | Warchief %s
--   193  | %s, Chosen of the Aspects
--   194  | Arch-Druid %s
--   195  | %s, Guardian of Tirisfal
--   196  | %s, Bane of the Black Empire
--   197  | %s the Forsaken
--   198  | %s the Deathless
--   199  | %s, Liberator of Outland
--   200  | Fel-Sworn %s
--   201  | %s, the Nightmare's End
--   202  | %s of the Highmountain
-- ============================================================
