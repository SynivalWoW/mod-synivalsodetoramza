-- ============================================================
-- mod-synival-paragon | Endgame Sets — Hunter, Death Knight,
--                       Shaman, Druid + Class Vendor NPCs
-- ============================================================
-- Run against your WORLD database (acpb_world).
--
-- Entry ID ranges used:
--   Items   : 99560–99599  (10 per class × 4 classes)
--   NPCs    : 99991–99994  (one per class)
--
-- Item slot layout per class (10 items total):
--   +0  Weapon      +1  Helm       +2  Chest
--   +3  Gloves      +4  Legs       +5  Boots
--   +6  Ring 1      +7  Ring 2     +8  Trinket 1
--   +9  Trinket 2
--
-- AllowableClass bitmask: Hunter=4 DK=32 Shaman=64 Druid=2048
--
-- Stat types: 1=Str 2=Agi 3=Sta 4=Int 5=Spi
--             7=Crit% 8=Haste% 9=SpPwr 10=AttPwr
--
-- InventoryType:
--   1=Head 5=Chest 8=Feet 10=Hands 11=Finger
--   12=Trinket 13=1H 15=Ranged 17=Staff
-- ============================================================

-- ============================================================
-- ITEM TEMPLATE — shared column list for all inserts
-- ============================================================
-- Columns: entry, class, subclass, SoundOverrideSubclass,
--   name, displayid, Quality, Flags, FlagsExtra,
--   BuyCount, BuyPrice, SellPrice,
--   InventoryType, AllowableClass, AllowableRace,
--   ItemLevel, RequiredLevel, RequiredSkill, RequiredSkillRank,
--   requiredspell, requiredhonorrank, RequiredCityRank,
--   RequiredReputationFaction, RequiredReputationRank,
--   maxcount, stackable, ContainerSlots,
--   stat_type1, stat_value1, stat_type2, stat_value2,
--   stat_type3, stat_value3, stat_type4, stat_value4,
--   stat_type5, stat_value5,
--   ScalingStatDistribution, ScalingStatValue,
--   dmg_min1, dmg_max1, dmg_type1,
--   dmg_min2, dmg_max2, dmg_type2,
--   armor, delay, bonding, description,
--   Material, sheath, MaxDurability, VerifiedBuild
-- ============================================================

DELETE FROM `item_template` WHERE `entry` BETWEEN 99560 AND 99599;

INSERT INTO `item_template`
    (`entry`,`class`,`subclass`,`SoundOverrideSubclass`,
     `name`,`displayid`,`Quality`,`Flags`,`FlagsExtra`,
     `BuyCount`,`BuyPrice`,`SellPrice`,
     `InventoryType`,`AllowableClass`,`AllowableRace`,
     `ItemLevel`,`RequiredLevel`,`RequiredSkill`,`RequiredSkillRank`,
     `requiredspell`,`requiredhonorrank`,`RequiredCityRank`,
     `RequiredReputationFaction`,`RequiredReputationRank`,
     `maxcount`,`stackable`,`ContainerSlots`,
     `stat_type1`,`stat_value1`,`stat_type2`,`stat_value2`,
     `stat_type3`,`stat_value3`,`stat_type4`,`stat_value4`,
     `stat_type5`,`stat_value5`,
     `ScalingStatDistribution`,`ScalingStatValue`,
     `dmg_min1`,`dmg_max1`,`dmg_type1`,
     `dmg_min2`,`dmg_max2`,`dmg_type2`,
     `armor`,`delay`,`bonding`,`description`,
     `Material`,`sheath`,`MaxDurability`,`VerifiedBuild`)
VALUES

-- ============================================================
-- HUNTER (99560–99569)   AllowableClass = 4
-- Theme: Apex Predator — strikes from the shadows of Icecrown
-- Primary stats: Agi, Sta, AttPwr, Crit
-- ============================================================

-- +0 Weapon: Ranged bow (InventoryType 15, subclass 2)
(99560,2,2,-1,'Apex Predator, Longbow of the Frozen Wilds',45265,5,0,0,
 1,0,0, 15,4,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 2,340, 3,320, 10,400, 7,140, 0,0,
 0,0, 340,560,0, 0,0,0,
 0, 3000, 1,'A bow carved from a Vrykul longbow, tipped with blackened arrowheads.',
 -1,6,0,0),

-- +1 Helm (InventoryType 1, subclass 3 = Mail)
(99561,4,3,-1,'Predator''s Crown of the Frozen Wilds',41273,5,0,0,
 1,0,0, 1,4,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 2,310, 3,330, 10,260, 7,120, 0,0,
 0,0, 0,0,0, 0,0,0,
 2400, 0, 1,'See through the blizzard. Strike before they see you.',
 -1,0,80,0),

-- +2 Chest (InventoryType 5, subclass 3 = Mail)
(99562,4,3,-1,'Beastmaster''s Chestguard of the Frozen Wilds',41158,5,0,0,
 1,0,0, 5,4,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 2,330, 3,360, 10,280, 8,120, 0,0,
 0,0, 0,0,0, 0,0,0,
 2800, 0, 1,'Forged for a predator who hunts alone in Icecrown.',
 -1,0,100,0),

-- +3 Gloves (InventoryType 10, subclass 3 = Mail)
(99563,4,3,-1,'Stalker''s Grips of the Frozen Wilds',41259,5,0,0,
 1,0,0, 10,4,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 2,250, 3,270, 10,220, 7,100, 0,0,
 0,0, 0,0,0, 0,0,0,
 1600, 0, 1,'Draw the bowstring without sound. Release without mercy.',
 -1,0,60,0),

-- +4 Legs (InventoryType 7, subclass 3 = Mail)
(99564,4,3,-1,'Legguards of the Apex Predator',41270,5,0,0,
 1,0,0, 7,4,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 2,280, 3,310, 10,250, 8,110, 0,0,
 0,0, 0,0,0, 0,0,0,
 2000, 0, 1,'Move without sound across any terrain.',
 -1,0,90,0),

-- +5 Boots (InventoryType 8, subclass 3 = Mail)
(99565,4,3,-1,'Tracker''s Sabatons of the Frozen Wilds',40649,5,0,0,
 1,0,0, 8,4,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 2,210, 3,240, 10,195, 7,90, 0,0,
 0,0, 0,0,0, 0,0,0,
 1800, 0, 1,'Leave no tracks. Follow every trail.',
 -1,0,70,0),

-- +6 Ring 1 (InventoryType 11)
(99566,4,0,-1,'Signet of the Apex Predator',52459,5,0,0,
 1,0,0, 11,4,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 2,220, 10,280, 7,130, 3,200, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'Engraved with the mark of every beast you have felled.',
 -1,0,0,0),

-- +7 Ring 2 (InventoryType 11)
(99567,4,0,-1,'Band of the Frozen Hunt',52632,5,0,0,
 1,0,0, 11,4,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 2,200, 10,260, 8,110, 3,190, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'Cooled to the temperature of Icecrown itself.',
 -1,0,0,0),

-- +8 Trinket 1 — offensive (InventoryType 12)
(99568,4,0,-1,'Fang of the Apex',59319,5,0,0,
 1,0,0, 12,4,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 2,280, 10,360, 7,160, 0,0, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'A shard of frozen beast-bone that hums with predatory intent.',
 -1,0,0,0),

-- +9 Trinket 2 — defensive/utility (InventoryType 12)
(99569,4,0,-1,'Mark of the Eternal Hunt',59322,5,0,0,
 1,0,0, 12,4,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 3,320, 2,260, 8,130, 0,0, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'Your prey cannot hide. Your prey cannot flee.',
 -1,0,0,0),


-- ============================================================
-- DEATH KNIGHT (99570–99579)   AllowableClass = 32
-- Theme: Soulreaper — born of Icecrown's deepest frost
-- Primary stats: Str, Sta, Armor, AttPwr
-- Weapon: 2H Axe (subclass 1, InventoryType 17→actually 13 for 2H melee)
-- ============================================================

-- +0 Weapon: 2H Axe (class 2, sub 1, InventoryType 17 = 2H general)
(99570,2,1,-1,'Soulreaper, Axe of the Death Gate',65153,5,0,0,
 1,0,0, 17,32,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 1,380, 3,350, 10,420, 7,150, 0,0,
 0,0, 500,760,0, 0,0,0,
 0, 2600, 1,'Forged in the Death Gate. Every swing tears a soul from its vessel.',
 -1,3,120,0),

-- +1 Helm (InventoryType 1, subclass 6 = Plate)
(99571,4,6,-1,'Helm of the Death Gate',41273,5,0,0,
 1,0,0, 1,32,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 1,340, 3,320, 10,290, 7,130, 0,0,
 0,0, 0,0,0, 0,0,0,
 3800, 0, 1,'The visor shows only frost and death.',
 -1,0,80,0),

-- +2 Chest (InventoryType 5, subclass 6 = Plate)
(99572,4,6,-1,'Runeplate of the Soulreaper',41158,5,0,0,
 1,0,0, 5,32,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 1,360, 3,390, 10,320, 8,140, 0,0,
 0,0, 0,0,0, 0,0,0,
 5200, 0, 1,'Etched with runes that drink the life of your enemies.',
 -1,0,100,0),

-- +3 Gloves (InventoryType 10, subclass 6 = Plate)
(99573,4,6,-1,'Gauntlets of the Soulreaper',41259,5,0,0,
 1,0,0, 10,32,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 1,270, 3,300, 10,250, 8,120, 0,0,
 0,0, 0,0,0, 0,0,0,
 2600, 0, 1,'The grip of death itself.',
 -1,0,60,0),

-- +4 Legs (InventoryType 7, subclass 6 = Plate)
(99574,4,6,-1,'Legplates of the Death Gate',41270,5,0,0,
 1,0,0, 7,32,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 1,310, 3,350, 10,280, 7,130, 0,0,
 0,0, 0,0,0, 0,0,0,
 4200, 0, 1,'March without rest. Feel no pain.',
 -1,0,90,0),

-- +5 Boots (InventoryType 8, subclass 6 = Plate)
(99575,4,6,-1,'Sabatons of the Death Gate',40649,5,0,0,
 1,0,0, 8,32,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 1,260, 3,290, 10,240, 8,120, 0,0,
 0,0, 0,0,0, 0,0,0,
 3100, 0, 1,'Carry you from one battlefield to the next, forever.',
 -1,0,70,0),

-- +6 Ring 1 (InventoryType 11)
(99576,4,0,-1,'Signet of the Soulreaper',64229,5,0,0,
 1,0,0, 11,32,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 1,240, 10,310, 7,140, 3,220, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'Cold to the touch. Warm with stolen life.',
 -1,0,0,0),

-- +7 Ring 2 (InventoryType 11)
(99577,4,0,-1,'Band of Eternal Frost',63960,5,0,0,
 1,0,0, 11,32,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 1,220, 10,290, 8,120, 3,210, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'The frost within it never melts.',
 -1,0,0,0),

-- +8 Trinket 1 — offensive (InventoryType 12)
(99578,4,0,-1,'Shard of the Death Gate',59319,5,0,0,
 1,0,0, 12,32,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 1,300, 10,400, 7,160, 0,0, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'A fragment of the gate between life and death.',
 -1,0,0,0),

-- +9 Trinket 2 — survival (InventoryType 12)
(99579,4,0,-1,'Talisman of Undying Will',59316,5,0,0,
 1,0,0, 12,32,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 3,370, 1,270, 8,130, 0,0, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'You have already died once. You will not do so again.',
 -1,0,0,0),


-- ============================================================
-- SHAMAN (99580–99589)   AllowableClass = 64
-- Theme: Worldbreaker — elemental mastery of Northrend's storms
-- Primary stats: Int, Sta, SpPwr, Haste / Agi, AttPwr (hybrid)
-- Weapon: Staff (class 2, sub 10, InventoryType 17)
-- ============================================================

-- +0 Weapon: Staff (class 2, sub 10, InventoryType 17)
(99580,2,10,-1,'Worldbreaker, Staff of the Maelstrom',54870,5,0,0,
 1,0,0, 17,64,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 4,360, 5,340, 9,400, 8,140, 0,0,
 0,0, 160,270,0, 0,0,0,
 0, 2000, 1,'The storm answers to its wielder. Everything else answers to the storm.',
 -1,0,120,0),

-- +1 Helm (InventoryType 1, subclass 4 = Mail)
(99581,4,4,-1,'Helm of the Worldbreaker',41273,5,0,0,
 1,0,0, 1,64,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 4,310, 5,290, 9,340, 3,280, 0,0,
 0,0, 0,0,0, 0,0,0,
 2500, 0, 1,'Carved from storm-touched stone of the Storm Peaks.',
 -1,0,80,0),

-- +2 Chest (InventoryType 5, subclass 4 = Mail)
(99582,4,4,-1,'Vest of the Worldbreaker',41158,5,0,0,
 1,0,0, 5,64,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 4,330, 5,310, 9,370, 8,130, 0,0,
 0,0, 0,0,0, 0,0,0,
 2700, 0, 1,'Lightning is woven into every link of this mail.',
 -1,0,100,0),

-- +3 Gloves (InventoryType 10, subclass 4 = Mail)
(99583,4,4,-1,'Grips of the Worldbreaker',41259,5,0,0,
 1,0,0, 10,64,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 4,240, 5,220, 9,270, 8,110, 0,0,
 0,0, 0,0,0, 0,0,0,
 1500, 0, 1,'Feel the elements surge through your hands.',
 -1,0,60,0),

-- +4 Legs (InventoryType 7, subclass 4 = Mail)
(99584,4,4,-1,'Kilt of the Worldbreaker',41270,5,0,0,
 1,0,0, 7,64,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 4,270, 5,250, 9,300, 8,120, 0,0,
 0,0, 0,0,0, 0,0,0,
 1800, 0, 1,'Woven with totemic sigils of all four elements.',
 -1,0,90,0),

-- +5 Boots (InventoryType 8, subclass 4 = Mail)
(99585,4,4,-1,'Treads of the Worldbreaker',40649,5,0,0,
 1,0,0, 8,64,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 4,205, 5,190, 9,230, 3,200, 0,0,
 0,0, 0,0,0, 0,0,0,
 1600, 0, 1,'Walk between the storms without faltering.',
 -1,0,70,0),

-- +6 Ring 1 (InventoryType 11)
(99586,4,0,-1,'Signet of the Worldbreaker',52459,5,0,0,
 1,0,0, 11,64,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 4,230, 9,290, 8,130, 5,200, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'The four elemental runes never stop moving.',
 -1,0,0,0),

-- +7 Ring 2 (InventoryType 11)
(99587,4,0,-1,'Band of the Ancestor''s Storm',52632,5,0,0,
 1,0,0, 11,64,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 4,210, 9,270, 5,190, 3,180, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'Your ancestors channelled storms through this ring. Now you do.',
 -1,0,0,0),

-- +8 Trinket 1 — elemental damage (InventoryType 12)
(99588,4,0,-1,'Eye of the Maelstrom',59319,5,0,0,
 1,0,0, 12,64,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 4,290, 9,370, 8,150, 0,0, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'Stare into it long enough and the storm stares back.',
 -1,0,0,0),

-- +9 Trinket 2 — restoration/endurance (InventoryType 12)
(99589,4,0,-1,'Totem of the Worldbreaker',59322,5,0,0,
 1,0,0, 12,64,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 5,270, 3,310, 4,240, 0,0, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'The ancestors speak through it. Listen.',
 -1,0,0,0),


-- ============================================================
-- DRUID (99590–99599)   AllowableClass = 2048
-- Theme: Ancient Grove — nature''s chosen in defiance of the Scourge
-- Primary stats: Agi/AttPwr (Feral) and Int/SpPwr (Balance/Resto)
-- Weapon: Staff (class 2, sub 10, InventoryType 17)
-- ============================================================

-- +0 Weapon: Staff (class 2, sub 10, InventoryType 17)
(99590,2,10,-1,'Heartwood, Staff of the Ancient Grove',35595,5,0,0,
 1,0,0, 17,2048,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 5,350, 4,360, 9,390, 2,280, 0,0,
 0,0, 150,250,0, 0,0,0,
 0, 2000, 1,'Cut from the last living tree in the Plaguelands. It still blooms.',
 -1,0,120,0),

-- +1 Helm (InventoryType 1, subclass 4 = Leather)
(99591,4,4,-1,'Crown of the Ancient Grove',41273,5,0,0,
 1,0,0, 1,2048,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 5,300, 4,320, 9,340, 2,270, 0,0,
 0,0, 0,0,0, 0,0,0,
 1900, 0, 1,'Antlers grown from living wood that remembers the world before the Sundering.',
 -1,0,80,0),

-- +2 Chest (InventoryType 5, subclass 4 = Leather)
(99592,4,4,-1,'Raiment of the Ancient Grove',41158,5,0,0,
 1,0,0, 5,2048,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 5,320, 4,340, 9,370, 3,300, 0,0,
 0,0, 0,0,0, 0,0,0,
 2000, 0, 1,'Woven from bark and root. Harder than plate in the hands of the worthy.',
 -1,0,100,0),

-- +3 Gloves (InventoryType 10, subclass 4 = Leather)
(99593,4,4,-1,'Grips of the Ancient Grove',41259,5,0,0,
 1,0,0, 10,2048,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 5,240, 4,260, 9,280, 2,230, 0,0,
 0,0, 0,0,0, 0,0,0,
 1200, 0, 1,'Roots curl around the wearer''s hands when the grove is threatened.',
 -1,0,60,0),

-- +4 Legs (InventoryType 7, subclass 4 = Leather)
(99594,4,4,-1,'Leggings of the Ancient Grove',41270,5,0,0,
 1,0,0, 7,2048,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 5,270, 4,290, 9,310, 3,270, 0,0,
 0,0, 0,0,0, 0,0,0,
 1700, 0, 1,'The forests of Azeroth remember every step taken in these.',
 -1,0,90,0),

-- +5 Boots (InventoryType 8, subclass 4 = Leather)
(99595,4,4,-1,'Treads of the Ancient Grove',40649,5,0,0,
 1,0,0, 8,2048,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 5,210, 4,230, 9,250, 2,200, 0,0,
 0,0, 0,0,0, 0,0,0,
 1500, 0, 1,'Wherever you walk, life follows in your footsteps.',
 -1,0,70,0),

-- +6 Ring 1 (InventoryType 11)
(99596,4,0,-1,'Signet of the Ancient Grove',52459,5,0,0,
 1,0,0, 11,2048,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 5,230, 9,300, 4,240, 2,210, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'A ring carved from petrified heartwood. Still warm to the touch.',
 -1,0,0,0),

-- +7 Ring 2 (InventoryType 11)
(99597,4,0,-1,'Band of the Verdant Cycle',52632,5,0,0,
 1,0,0, 11,2048,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 5,210, 9,280, 3,250, 4,220, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'Life, death, and rebirth — the cycle never ends.',
 -1,0,0,0),

-- +8 Trinket 1 — caster/nature damage (InventoryType 12)
(99598,4,0,-1,'Heart of the Ancient Grove',59319,5,0,0,
 1,0,0, 12,2048,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 4,300, 9,380, 5,260, 0,0, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'It pulses like a living thing. Because it is.',
 -1,0,0,0),

-- +9 Trinket 2 — feral/physical (InventoryType 12)
(99599,4,0,-1,'Claw of the Primal Grove',59316,5,0,0,
 1,0,0, 12,2048,-1, 284,80,0,0,0,0,0,0,0, 1,1,0,
 2,300, 10,380, 7,150, 3,260, 0,0,
 0,0, 0,0,0, 0,0,0,
 0, 0, 1,'Taken from the paw of the oldest forest cat in Azeroth.',
 -1,0,0,0);


-- ============================================================
-- VENDOR NPCs — one per class
-- Entries: 99991 (Hunter), 99992 (Death Knight),
--          99993 (Shaman),  99994 (Druid)
-- All spawn in Dalaran (map 571), near the Runic Archive.
-- npcflag = 1 (GOSSIP) — wired to ScriptName for vendor logic.
-- ============================================================

DELETE FROM `creature_template` WHERE `entry` IN (99991, 99992, 99993, 99994);

INSERT INTO `creature_template`
    (`entry`,`difficulty_entry_1`,`difficulty_entry_2`,`difficulty_entry_3`,
     `KillCredit1`,`KillCredit2`,
     `name`,`subname`,`IconName`,
     `gossip_menu_id`,`minlevel`,`maxlevel`,`exp`,`faction`,`npcflag`,
     `speed_walk`,`speed_run`,`speed_swim`,`speed_flight`,`detection_range`,
     `scale`,`rank`,`dmgschool`,
     `BaseAttackTime`,`RangeAttackTime`,`BaseVariance`,`RangeVariance`,
     `unit_class`,`unit_flags`,`unit_flags2`,`dynamicflags`,
     `family`,`type`,`type_flags`,
     `lootid`,`pickpocketloot`,`skinloot`,`PetSpellDataId`,`VehicleId`,
     `mingold`,`maxgold`,`AIName`,`MovementType`,`HoverHeight`,
     `HealthModifier`,`ManaModifier`,`ArmorModifier`,
     `DamageModifier`,`ExperienceModifier`,`RacialLeader`,`movementId`,
     `RegenHealth`,`mechanic_immune_mask`,`spell_school_immune_mask`,
     `flags_extra`,`ScriptName`,`VerifiedBuild`)
VALUES
-- ── Hunter Vendor: Rhayara Swiftwind — a Night Elf Huntress ──────────────────
(99991, 0,0,0, 0,0,
 'Rhayara Swiftwind','Apex Arcanist','Speak',
 99991, 80,80, 2,35,1,
 1.0,1.14286,1.0,1.0, 20.0,
 1.0,0,0,
 2000,2000, 1.0,1.0,
 1,2,0,0,
 0,7,0,
 0,0,0,0,0,
 0,0,'ReactorAI',0,1.0,
 1.0,1.0,1.0, 1.0,1.0, 0,0,
 1,0,0,
 16777216,'npc_legendary_vendor_hunter',0),

-- ── Death Knight Vendor: Velthas Dreadblade — armoured DK male ───────────────
(99992, 0,0,0, 0,0,
 'Velthas Dreadblade','Deathblade Arcanist','Speak',
 99992, 80,80, 2,35,1,
 1.0,1.14286,1.0,1.0, 20.0,
 1.1,0,0,
 2000,2000, 1.0,1.0,
 1,2,0,0,
 0,7,0,
 0,0,0,0,0,
 0,0,'ReactorAI',0,1.0,
 1.0,1.0,1.0, 1.0,1.0, 0,0,
 1,0,0,
 16777216,'npc_legendary_vendor_dk',0),

-- ── Shaman Vendor: Murak Stormcaller — Orc shaman ────────────────────────────
(99993, 0,0,0, 0,0,
 'Murak Stormcaller','Stormcaller Arcanist','Speak',
 99993, 80,80, 2,35,1,
 1.0,1.14286,1.0,1.0, 20.0,
 1.0,0,0,
 2000,2000, 1.0,1.0,
 1,2,0,0,
 0,7,0,
 0,0,0,0,0,
 0,0,'ReactorAI',0,1.0,
 1.0,1.0,1.0, 1.0,1.0, 0,0,
 1,0,0,
 16777216,'npc_legendary_vendor_shaman',0),

-- ── Druid Vendor: Sylara Hearthroot — Night Elf female druid ─────────────────
(99994, 0,0,0, 0,0,
 'Sylara Hearthroot','Grove Arcanist','Speak',
 99994, 80,80, 2,35,1,
 1.0,1.14286,1.0,1.0, 20.0,
 1.0,0,0,
 2000,2000, 1.0,1.0,
 1,2,0,0,
 0,7,0,
 0,0,0,0,0,
 0,0,'ReactorAI',0,1.0,
 1.0,1.0,1.0, 1.0,1.0, 0,0,
 1,0,0,
 16777216,'npc_legendary_vendor_druid',0);


-- ============================================================
-- creature_template_model
-- ============================================================
-- Display IDs chosen from creature_template DB:
--   99991 Hunter  : 17341 — Night Elf Huntress (entry 17945)
--   99992 DK      : 23649 — Thassarian (entry 26170, DK plate)
--   99993 Shaman  : 17600 — Farseer Nobundo (entry 17204)
--   99994 Druid   : 15399 — Malfurion Stormrage (entry 17949)
-- ============================================================

DELETE FROM `creature_template_model` WHERE `CreatureID` IN (99991, 99992, 99993, 99994);

INSERT INTO `creature_template_model`
    (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`)
VALUES
 (99991, 0, 17341, 1.0, 1.0, 0),
 (99992, 0, 23649, 1.1, 1.0, 0),
 (99993, 0, 17600, 1.0, 1.0, 0),
 (99994, 0, 15399, 1.0, 1.0, 0);


-- ============================================================
-- creature  (spawn records — Dalaran, near Runic Archive)
-- ============================================================
-- Positions are clustered around the Runic Archive at (5813, 623, 647)
-- spaced ~6 units apart along the x-axis so they don't overlap.
-- ============================================================

DELETE FROM `creature` WHERE `id1` IN (99991, 99992, 99993, 99994);

INSERT INTO `creature`
    (`id1`,`id2`,`id3`,
     `map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,
     `position_x`,`position_y`,`position_z`,`orientation`,
     `spawntimesecs`,`wander_distance`,`currentwaypoint`,
     `curhealth`,`curmana`,`MovementType`,
     `npcflag`,`unit_flags`,`dynamicflags`,
     `ScriptName`,`VerifiedBuild`,`CreateObject`,`Comment`)
VALUES
 (99991,0,0, 571,0,0, 1,1,0, 5820.50,623.43,647.57,4.71,
  300,0.0,0, 1,0,0, 0,0,0, NULL,NULL,0,
  'mod-synival-paragon: Rhayara Swiftwind — Hunter Legendary Vendor'),

 (99992,0,0, 571,0,0, 1,1,0, 5826.50,623.43,647.57,4.71,
  300,0.0,0, 1,0,0, 0,0,0, NULL,NULL,0,
  'mod-synival-paragon: Velthas Dreadblade — Death Knight Legendary Vendor'),

 (99993,0,0, 571,0,0, 1,1,0, 5832.50,623.43,647.57,4.71,
  300,0.0,0, 1,0,0, 0,0,0, NULL,NULL,0,
  'mod-synival-paragon: Murak Stormcaller — Shaman Legendary Vendor'),

 (99994,0,0, 571,0,0, 1,1,0, 5838.50,623.43,647.57,4.71,
  300,0.0,0, 1,0,0, 0,0,0, NULL,NULL,0,
  'mod-synival-paragon: Sylara Hearthroot — Druid Legendary Vendor');


-- ============================================================
-- npc_text — one greeting per vendor
-- ============================================================

DELETE FROM `npc_text` WHERE `ID` IN (99991, 99992, 99993, 99994);

INSERT INTO `npc_text`
    (`ID`,`text0_0`,`text0_1`,`lang0`,`Probability0`,
     `em0_0`,`em0_1`,`em0_2`,`em0_3`,`em0_4`,`em0_5`,
     `text1_0`,`text1_1`,`lang1`,`Probability1`,
     `em1_0`,`em1_1`,`em1_2`,`em1_3`,`em1_4`,`em1_5`,
     `text2_0`,`text2_1`,`lang2`,`Probability2`,
     `em2_0`,`em2_1`,`em2_2`,`em2_3`,`em2_4`,`em2_5`,
     `text3_0`,`text3_1`,`lang3`,`Probability3`,
     `em3_0`,`em3_1`,`em3_2`,`em3_3`,`em3_4`,`em3_5`,
     `text4_0`,`text4_1`,`lang4`,`Probability4`,
     `em4_0`,`em4_1`,`em4_2`,`em4_3`,`em4_4`,`em4_5`,
     `text5_0`,`text5_1`,`lang5`,`Probability5`,
     `em5_0`,`em5_1`,`em5_2`,`em5_3`,`em5_4`,`em5_5`,
     `text6_0`,`text6_1`,`lang6`,`Probability6`,
     `em6_0`,`em6_1`,`em6_2`,`em6_3`,`em6_4`,`em6_5`,
     `text7_0`,`text7_1`,`lang7`,`Probability7`,
     `em7_0`,`em7_1`,`em7_2`,`em7_3`,`em7_4`,`em7_5`,
     `VerifiedBuild`)
VALUES
(99991,
 'The apex predator does not hesitate, $N. Neither should you.',
 'The apex predator does not hesitate, $N. Neither should you.',
 0,1, 0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 0),
(99992,
 'Death waits for no one, $N. Least of all you.',
 'Death waits for no one, $N. Least of all you.',
 0,1, 0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 0),
(99993,
 'The elements have guided you here, $N. They rarely do that by accident.',
 'The elements have guided you here, $N. They rarely do that by accident.',
 0,1, 0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 0),
(99994,
 'The grove endures, $N. With this, so shall you.',
 'The grove endures, $N. With this, so shall you.',
 0,1, 0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 NULL,NULL,0,0,0,0,0,0,0,0,
 0);

SELECT 'endgame_sets.sql applied — 40 items (99560-99599), 4 NPCs (99991-99994).' AS Status;
