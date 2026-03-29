-- ============================================================
-- mod-synival-loot | world database
-- ============================================================
-- Run against your WORLD database before starting the server.
-- Uses minimal explicit-column INSERTs to avoid schema mismatches.
-- Entry ID ranges: 99500-99559 (legendary items), 99995 (vendor NPC)
-- ============================================================

-- ============================================================
-- LEGENDARY VENDOR NPC (entry 99995)
-- ============================================================
USE acpb_world;
DELETE FROM `creature_template` WHERE `entry` = 99995;
INSERT INTO `creature_template`
    (`entry`,`name`,`subname`,`gossip_menu_id`,`minlevel`,`maxlevel`,
     `exp`,`faction`,`npcflag`,`speed_walk`,`speed_run`,`scale`,
     `unit_class`,`unit_flags`,`type`,`AIName`,`MovementType`,
     `flags_extra`,`ScriptName`,`VerifiedBuild`)
VALUES
    (99995,'Synival','Legendary Arcanist',99995,80,80,
     2,35,1,1.0,1.14286,1.1,
     1,2,7,'ReactorAI',0,
     16777216,'npc_legendary_vendor',0);

-- ============================================================
-- creature_template_model
-- Required by modern AzerothCore — links NPC entries to model IDs.
-- DisplayID 27342 = Vindicator Maraad (entry 30833) — powerful armoured Draenei paladin,
-- fitting the theme of a Legendary equipment vendor tied to Paragon ascension.
-- ============================================================

DELETE FROM `creature_template_model` WHERE `CreatureID` = 99995;
INSERT INTO `creature_template_model`
    (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
VALUES
    (99995, 0, 27342, 1.0, 1.0, 0);  -- Vindicator Maraad (entry 30833)



DELETE FROM `creature` WHERE `id1` = 99995;
INSERT INTO `creature`
    (`id1`,`map`,`spawnMask`,`phaseMask`,
     `position_x`,`position_y`,`position_z`,`orientation`,
     `spawntimesecs`,`wander_distance`,`currentwaypoint`,
     `curhealth`,`curmana`,`MovementType`)
VALUES
    (99995,571,1,1,
     5814.50,624.10,647.57,4.71,
     300,0.0,0,
     1,0,0);

-- npc_text
DELETE FROM `npc_text` WHERE `ID` = 99995;
INSERT INTO `npc_text`
    (`ID`,`text0_0`,`text0_1`,`lang0`,`Probability0`,
     `em0_0`,`em0_1`,`em0_2`,`em0_3`,`em0_4`,`em0_5`,
     `VerifiedBuild`)
VALUES
    (99995,
     'Your potential is etched in Paragon energy, $N. Shall we forge something worthy of it?',
     'Your potential is etched in Paragon energy, $N. Shall we forge something worthy of it?',
     0,1,
     0,0,0,0,0,0,
     0);

-- ============================================================
-- LEGENDARY ITEM TEMPLATES (entries 99500-99559)
-- Minimal column set — only non-default values supplied.
-- Stat types: 1=Agi 3=Sta 4=Str 5=Int 6=Spi 7=Haste
--             8=Hit 9=SpPwr 10=AttPwr
-- InventoryType: 1=Head 5=Chest 7=Legs 8=Feet 10=Hands
--                13=1H 15=Ranged 17=Staff
-- AllowableClass: War=1 Pal=2 Hun=4 Rog=8 Pri=16
--                 DK=32 Sha=64 Mag=128 Wlk=256 Dru=2048
-- ============================================================

DELETE FROM `item_template` WHERE `entry` BETWEEN 99500 AND 99559;

INSERT INTO `item_template`
    (`entry`,`class`,`subclass`,`SoundOverrideSubclass`,
     `name`,`displayid`,`Quality`,
     `InventoryType`,`AllowableClass`,`AllowableRace`,
     `ItemLevel`,`RequiredLevel`,`maxcount`,`stackable`,
     `stat_type1`,`stat_value1`,`stat_type2`,`stat_value2`,
     `stat_type3`,`stat_value3`,`stat_type4`,`stat_value4`,
     `stat_type5`,`stat_value5`,
     `dmg_min1`,`dmg_max1`,`dmg_type1`,
     `armor`,`delay`,`bonding`,`description`,
     `Material`,`sheath`,`MaxDurability`,`VerifiedBuild`)
VALUES
-- ── WARRIOR (99500-99505) ────────────────────────────────────
(99500,2,7,-1,'Ironbreaker, Edge of Warlords',49282,5,
 13,1,-1,284,80,1,1,
 4,350,1,300,3,280,10,400,7,120,
 450,680,0,0,2600,1,'Forged in the blood of ten thousand battles.',-1,3,120,0),

(99501,4,0,-1,'Warmaster''s Crown of Dominion',41273,5,
 1,1,-1,284,80,1,1,
 4,300,3,350,10,250,8,100,0,0,
 0,0,0,3200,0,1,'The crown of a true warlord.',-1,0,80,0),

(99502,4,2,-1,'Battleplate of the Iron Juggernaut',41158,5,
 5,1,-1,284,80,1,1,
 4,320,3,380,10,280,7,110,0,0,
 0,0,0,4500,0,1,'Iron inside and out.',-1,0,100,0),

(99503,4,2,-1,'Gauntlets of Unending War',41259,5,
 10,1,-1,284,80,1,1,
 4,240,3,270,10,220,8,90,0,0,
 0,0,0,2200,0,1,'Your grip never loosens.',-1,0,60,0),

(99504,4,2,-1,'Legplates of the Warborn',41270,5,
 7,1,-1,284,80,1,1,
 4,280,3,320,10,260,7,100,0,0,
 0,0,0,3800,0,1,'Forged for the march that never ends.',-1,0,90,0),

(99505,4,2,-1,'Stompers of the Fallen Champion',40649,5,
 8,1,-1,284,80,1,1,
 4,230,3,260,10,210,8,85,0,0,
 0,0,0,2800,0,1,'The earth trembles at every step.',-1,0,70,0),

-- ── PALADIN (99506-99511) ────────────────────────────────────
(99506,2,7,-1,'Lightbringer, Blade of the Eternal',49282,5,
 13,2,-1,284,80,1,1,
 4,320,5,300,9,350,7,130,10,280,
 400,620,0,0,2600,1,'Blessed by the naaru themselves.',-1,3,120,0),

(99507,4,2,-1,"Helm of the Crusader Ascendant",41273,5,
 1,2,-1,284,80,1,1,
 4,280,5,260,3,300,9,220,7,100,
 0,0,0,3000,0,1,'Light made manifest.',-1,0,80,0),

(99508,4,2,-1,'Breastplate of Sacred Covenant',41158,5,
 5,2,-1,284,80,1,1,
 4,300,5,280,3,340,9,240,0,0,
 0,0,0,4200,0,1,'The Light is your shield.',-1,0,100,0),

(99509,4,2,-1,'Gauntlets of Divine Retribution',41259,5,
 10,2,-1,284,80,1,1,
 4,220,5,200,9,200,7,90,0,0,
 0,0,0,2000,0,1,'Strike with the fury of a thousand suns.',-1,0,60,0),

(99510,4,2,-1,'Legplates of the Holy Vanguard',41270,5,
 7,2,-1,284,80,1,1,
 4,260,5,240,3,290,9,210,0,0,
 0,0,0,3600,0,1,'Every step is a holy march.',-1,0,90,0),

(99511,4,2,-1,'Sabatons of the Radiant Crusade',40649,5,
 8,2,-1,284,80,1,1,
 4,210,5,190,3,240,9,185,0,0,
 0,0,0,2600,0,1,'Walk with the Light at your back.',-1,0,70,0),

-- ── HUNTER (99512-99517) ─────────────────────────────────────
(99512,2,3,-1,'Predator''s Fang, Bow of the Apex',32768,5,
 15,4,-1,284,80,1,1,
 3,350,1,300,10,400,7,130,0,0,
 350,560,0,0,3000,1,'The apex predator never misses.',-1,6,0,0),

(99513,4,3,-1,'Stalker''s Helm of the Wilds',41273,5,
 1,4,-1,284,80,1,1,
 3,300,1,260,10,250,7,110,0,0,
 0,0,0,2400,0,1,'See everything. Be seen by nothing.',-1,0,80,0),

(99514,4,3,-1,'Beastmaster''s Hunting Vest',41158,5,
 5,4,-1,284,80,1,1,
 3,320,1,280,10,270,7,120,0,0,
 0,0,0,2600,0,1,'The beast and the hunter are one.',-1,0,100,0),

(99515,4,3,-1,'Tracker''s Gloves of the Endless Hunt',41259,5,
 10,4,-1,284,80,1,1,
 3,240,1,210,10,200,7,90,0,0,
 0,0,0,1600,0,1,'Feel the arrow before it flies.',-1,0,60,0),

(99516,4,3,-1,'Legguards of the Pack Lord',41270,5,
 7,4,-1,284,80,1,1,
 3,260,1,230,10,240,7,100,0,0,
 0,0,0,2000,0,1,'Lead the pack. Be the pack.',-1,0,90,0),

(99517,4,3,-1,'Boots of the Silent Predator',40649,5,
 8,4,-1,284,80,1,1,
 3,210,1,185,10,190,8,90,0,0,
 0,0,0,1800,0,1,'Move without sound. Strike without warning.',-1,0,70,0),

-- ── ROGUE (99518-99523) ──────────────────────────────────────
(99518,2,15,-1,'Shadowfang, Dagger of the Void',49283,5,
 13,8,-1,284,80,1,1,
 3,320,1,340,10,360,7,150,8,100,
 200,380,0,0,1800,1,'Death lives in its edge.',-1,1,90,0),

(99519,4,3,-1,'Cowl of the Phantom Assassin',41273,5,
 1,8,-1,284,80,1,1,
 3,290,1,310,10,260,7,130,0,0,
 0,0,0,1800,0,1,'They never saw you.',-1,0,70,0),

(99520,4,3,-1,'Tunic of the Phantom Assassination',41158,5,
 5,8,-1,284,80,1,1,
 3,310,1,330,10,280,7,140,0,0,
 0,0,0,1900,0,1,'Shadows embrace you.',-1,0,90,0),

(99521,4,3,-1,'Handwraps of the Silent Blade',41259,5,
 10,8,-1,284,80,1,1,
 3,230,1,250,10,210,7,110,0,0,
 0,0,0,1200,0,1,'Every finger is a weapon.',-1,0,50,0),

(99522,4,3,-1,'Leggings of the Venom Artist',41270,5,
 7,8,-1,284,80,1,1,
 3,250,1,270,10,230,7,120,0,0,
 0,0,0,1600,0,1,'Coated in poisons none can name.',-1,0,80,0),

(99523,4,3,-1,'Treads of the Endless Shadow',40649,5,
 8,8,-1,284,80,1,1,
 3,200,1,220,10,195,8,85,0,0,
 0,0,0,1400,0,1,'Leave no footprint.',-1,0,60,0),

-- ── PRIEST (99524-99529) ─────────────────────────────────────
(99524,2,10,-1,'Radiance, Staff of the Holy Veil',35595,5,
 17,16,-1,284,80,1,1,
 5,340,4,360,9,400,7,130,8,110,
 180,280,0,0,2000,1,'The Light speaks through you.',-1,0,120,0),

(99525,4,1,-1,'Halo of the Sacred Veil',41273,5,
 1,16,-1,284,80,1,1,
 5,310,4,330,9,350,7,120,0,0,
 0,0,0,1600,0,1,'A halo earned, not given.',-1,0,70,0),

(99526,4,1,-1,'Vestments of the Seraphic Choir',41158,5,
 5,16,-1,284,80,1,1,
 5,330,4,350,9,370,8,120,0,0,
 0,0,0,1700,0,1,'Every prayer woven into every thread.',-1,0,90,0),

(99527,4,1,-1,'Gloves of the Eternal Supplicant',41259,5,
 10,16,-1,284,80,1,1,
 5,240,4,260,9,280,7,100,0,0,
 0,0,0,1000,0,1,'Healing flows from these hands.',-1,0,50,0),

(99528,4,1,-1,'Leggings of the Holy Covenant',41270,5,
 7,16,-1,284,80,1,1,
 5,270,4,290,9,310,8,110,0,0,
 0,0,0,1400,0,1,'Walk the path of peace.',-1,0,80,0),

(99529,4,1,-1,'Sandals of the Angelic Descent',40649,5,
 8,16,-1,284,80,1,1,
 5,210,4,230,9,250,8,100,0,0,
 0,0,0,1200,0,1,'Touch the world lightly.',-1,0,60,0),

-- ── DEATH KNIGHT (99530-99535) ───────────────────────────────
(99530,2,5,-1,'Frostmourne''s Echo, Blade of the Lich',49282,5,
 13,32,-1,284,80,1,1,
 4,360,3,340,10,380,7,150,0,0,
 500,740,0,0,2600,1,'Forged in eternal winter.',-1,3,120,0),

(99531,4,6,-1,'Helm of the Scourge Ascendant',41273,5,
 1,32,-1,284,80,1,1,
 4,320,3,300,10,280,7,130,0,0,
 0,0,0,3500,0,1,'Death stares back from its visor.',-1,0,80,0),

(99532,4,6,-1,'Saronite Runeplate of the Death Gate',41158,5,
 5,32,-1,284,80,1,1,
 4,340,3,360,10,310,7,140,0,0,
 0,0,0,5000,0,1,'The gate between life and death.',-1,0,100,0),

(99533,4,6,-1,'Gauntlets of the Lich''s Grasp',41259,5,
 10,32,-1,284,80,1,1,
 4,260,3,280,10,240,7,120,0,0,
 0,0,0,2500,0,1,'Even the grave cannot break this grip.',-1,0,60,0),

(99534,4,6,-1,'Legplates of the Risen Colossus',41270,5,
 7,32,-1,284,80,1,1,
 4,300,3,320,10,270,7,130,0,0,
 0,0,0,4000,0,1,'Risen to fight once more.',-1,0,90,0),

(99535,4,6,-1,'Sabatons of the Endless Scourge',40649,5,
 8,32,-1,284,80,1,1,
 4,250,3,270,10,230,7,120,0,0,
 0,0,0,3000,0,1,'March without end. Rest never.',-1,0,70,0),

-- ── SHAMAN (99536-99541) ─────────────────────────────────────
(99536,2,10,-1,'Stormcaller, Staff of the Maelstrom',35595,5,
 17,64,-1,284,80,1,1,
 5,330,4,350,9,380,7,130,8,120,
 160,260,0,0,2000,1,'The storm obeys your call.',-1,0,120,0),

(99537,4,4,-1,'Helm of the Earthen Ancestor',41273,5,
 1,64,-1,284,80,1,1,
 5,290,4,310,9,330,3,280,7,110,
 0,0,0,2500,0,1,'The ancestors watch through your eyes.',-1,0,70,0),

(99538,4,4,-1,'Vest of the Primal Stormcaller',41158,5,
 5,64,-1,284,80,1,1,
 5,310,4,330,9,360,8,130,0,0,
 0,0,0,2200,0,1,'Earth, fire, wind, water — all within.',-1,0,90,0),

(99539,4,4,-1,'Grips of the Thunder Totem',41259,5,
 10,64,-1,284,80,1,1,
 5,230,4,250,9,270,8,110,0,0,
 0,0,0,1400,0,1,'Call the elements with every gesture.',-1,0,50,0),

(99540,4,4,-1,'Kilt of the Ancestral Storm',41270,5,
 7,64,-1,284,80,1,1,
 5,260,4,280,9,300,8,120,0,0,
 0,0,0,1700,0,1,'Woven from lightning and earth.',-1,0,80,0),

(99541,4,4,-1,'Treads of the Primal Tide',40649,5,
 8,64,-1,284,80,1,1,
 5,200,4,220,9,240,8,100,0,0,
 0,0,0,1500,0,1,'Walk upon the water itself.',-1,0,60,0),

-- ── MAGE (99542-99547) ───────────────────────────────────────
(99542,2,10,-1,'Arcane Singularity, Staff of Infinite Power',35595,5,
 17,128,-1,284,80,1,1,
 5,360,4,380,9,420,8,140,7,130,
 150,240,0,0,2000,1,'Reality collapses into your will.',-1,0,120,0),

(99543,4,1,-1,'Crown of the Arcane Singularity',41273,5,
 1,128,-1,284,80,1,1,
 5,330,4,350,9,380,8,130,0,0,
 0,0,0,1500,0,1,'The nexus of all arcane power.',-1,0,70,0),

(99544,4,1,-1,'Robe of the Infinite Arcanum',41158,5,
 5,128,-1,284,80,1,1,
 5,350,4,370,9,400,8,140,0,0,
 0,0,0,1600,0,1,'Woven from condensed ley energy.',-1,0,90,0),

(99545,4,1,-1,'Gloves of the Arcane Weave',41259,5,
 10,128,-1,284,80,1,1,
 5,260,4,280,9,300,8,120,0,0,
 0,0,0,1000,0,1,'Trace the spell in the air itself.',-1,0,50,0),

(99546,4,1,-1,'Leggings of the Prismatic Confluence',41270,5,
 7,128,-1,284,80,1,1,
 5,290,4,310,9,330,8,130,0,0,
 0,0,0,1400,0,1,'Every thread a ley line.',-1,0,80,0),

(99547,4,1,-1,'Slippers of the Blink Sage',40649,5,
 8,128,-1,284,80,1,1,
 5,220,4,240,9,260,8,110,0,0,
 0,0,0,1100,0,1,'You are already somewhere else.',-1,0,60,0),

-- ── WARLOCK (99548-99553) ────────────────────────────────────
(99548,2,10,-1,'Ruinbringer, Staff of the Void Pact',35595,5,
 17,256,-1,284,80,1,1,
 5,340,4,360,9,400,3,300,8,120,
 150,240,0,0,2000,1,'The void answers only to you.',-1,0,120,0),

(99549,4,1,-1,'Cowl of the Fel Covenant',41273,5,
 1,256,-1,284,80,1,1,
 5,310,4,330,9,360,3,280,7,110,
 0,0,0,1500,0,1,'The pact is sealed with your blood.',-1,0,70,0),

(99550,4,1,-1,'Robe of the Void Harbinger',41158,5,
 5,256,-1,284,80,1,1,
 5,330,4,350,9,380,3,300,0,0,
 0,0,0,1600,0,1,'Darkness is a garment, not a curse.',-1,0,90,0),

(99551,4,1,-1,'Gloves of the Demon Pact',41259,5,
 10,256,-1,284,80,1,1,
 5,250,4,270,9,290,3,250,0,0,
 0,0,0,1000,0,1,'Sealed in fel fire. Bound in shadow.',-1,0,50,0),

(99552,4,1,-1,'Leggings of the Affliction Lord',41270,5,
 7,256,-1,284,80,1,1,
 5,280,4,300,9,320,3,270,0,0,
 0,0,0,1400,0,1,'Your curses flow from within.',-1,0,80,0),

(99553,4,1,-1,'Doomboots of the Void Harbinger',40649,5,
 8,256,-1,284,80,1,1,
 5,210,4,230,9,250,3,220,0,0,
 0,0,0,1200,0,1,'Every step forward is a step into the void.',-1,0,60,0),

-- ── DRUID (99554-99559) ──────────────────────────────────────
(99554,2,10,-1,'Verdant Heart, Staff of the Ancient Grove',35595,5,
 17,2048,-1,284,80,1,1,
 5,330,4,350,3,310,9,380,8,120,
 150,240,0,0,2000,1,'Nature answers to no master but itself.',-1,0,120,0),

(99555,4,4,-1,'Antlers of the Eternal Grove',41273,5,
 1,2048,-1,284,80,1,1,
 5,290,4,310,3,280,9,330,7,110,
 0,0,0,1800,0,1,'The forest crown of an ancient guardian.',-1,0,70,0),

(99556,4,4,-1,'Breastplate of the Verdant Cycle',41158,5,
 5,2048,-1,284,80,1,1,
 5,310,4,330,3,300,9,360,0,0,
 0,0,0,1900,0,1,'Life, death, and rebirth woven together.',-1,0,90,0),

(99557,4,4,-1,'Grips of the Primal Shapeshifter',41259,5,
 10,2048,-1,284,80,1,1,
 5,230,4,250,3,220,9,270,0,0,
 0,0,0,1200,0,1,'Shift between forms at will.',-1,0,50,0),

(99558,4,4,-1,'Leggings of the Ancient Cycle',41270,5,
 7,2048,-1,284,80,1,1,
 5,260,4,280,3,250,9,300,0,0,
 0,0,0,1600,0,1,'The forest grows through you.',-1,0,80,0),

(99559,4,4,-1,'Treads of the Ancient Grove',40649,5,
 8,2048,-1,284,80,1,1,
 5,200,4,220,3,190,9,240,0,0,
 0,0,0,1400,0,1,'Walk where no living thing has walked.',-1,0,60,0);
