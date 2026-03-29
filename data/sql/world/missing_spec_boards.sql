-- ============================================================
-- mod-synival-paragon | Missing Spec Board Nodes
-- Boards 12-16 (Warrior/Paladin/Hunter/Rogue/Priest specs)
-- and Board 17 nodes 1-28 (Retribution, partial completion)
-- ============================================================
-- Run against your WORLD database (acpb_world).
-- Uses INSERT IGNORE so it is safe to re-run.
-- ============================================================

-- ============================================================
-- BOARD 12 — Arms: Warmaster  (Strength%, Attack Power%)
-- Warrior spec — requires board 2 at Paragon 100
-- ============================================================
INSERT IGNORE INTO `paragon_board_nodes`
  (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(12, 1,3,3,4, 0,  0.0,'The Warmaster Path',      'Every swing ends a war.'),
(12, 2,3,1,1, 1,140.0,'Colossus Strength',       '+140 Strength'),
(12, 3,2,2,1,10,130.0,'Sweeping Strikes Power',  '+130 Attack Power'),
(12, 4,3,2,3, 0,  0.0,'Glyph Socket',            'Socket a Glyph.'),
(12, 5,4,2,1, 1,140.0,'Mortal Strike Might',     '+140 Strength'),
(12, 6,2,3,1,10,130.0,'Trauma Power',            '+130 Attack Power'),
(12, 7,4,3,1, 1,140.0,'Juggernaut Arms',         '+140 Strength'),
(12, 8,2,4,1, 3,115.0,'Arms Endurance',          '+115 Stamina'),
(12, 9,3,4,3, 0,  0.0,'Glyph Socket',            'Socket a Glyph.'),
(12,10,4,4,1,10,130.0,'Execute Power',           '+130 Attack Power'),
(12,11,3,5,1, 1,140.0,'Bladestorm Might',        '+140 Strength'),
(12,12,1,1,0, 1, 65.0,'Iron Arms',               '+65 Strength'),
(12,13,2,1,0,10, 58.0,'Overpower Strike',        '+58 Attack Power'),
(12,14,4,1,0, 1, 65.0,'War Veteran Muscle',      '+65 Strength'),
(12,15,5,1,0, 3, 52.0,'Arms Grit',               '+52 Stamina'),
(12,16,1,2,0,10, 58.0,'Blood Frenzy Power',      '+58 Attack Power'),
(12,17,5,2,0, 1, 65.0,'Titan Sinew',             '+65 Strength'),
(12,18,1,3,0, 1, 65.0,'Unbridled Fury',          '+65 Strength'),
(12,19,5,3,0, 3, 52.0,'Battle Hardened',         '+52 Stamina'),
(12,20,1,4,0,10, 58.0,'Deep Wounds Power',       '+58 Attack Power'),
(12,21,5,4,0, 1, 65.0,'Anger Management',        '+65 Strength'),
(12,22,1,5,0, 3, 52.0,'Iron Constitution',       '+52 Stamina'),
(12,23,2,5,0, 1, 65.0,'Poleaxe Mastery',         '+65 Strength'),
(12,24,4,5,0,10, 58.0,'Warbringer Power',        '+58 Attack Power'),
(12,25,5,5,0, 1, 65.0,'Colossus Smash Might',    '+65 Strength'),
(12,26,2,0,2, 1,  2.5,'Warmaster Might',         '+2.5% Strength'),
(12,27,4,0,2,10,  2.5,'Bladestorm Fury',         '+2.5% Attack Power'),
(12,28,0,2,2, 1,  2.0,'Arms Champion',           '+2.0% Strength'),
(12,29,6,2,2,10,  2.5,'Rend Power',              '+2.5% Attack Power'),
(12,30,0,4,2, 7,  1.2,'Precision Strikes',       '+1.2% Critical Strike'),
(12,31,6,4,2, 1,  2.5,'Colossus Strength Surge', '+2.5% Strength'),
(12,32,2,6,2, 7,  1.2,'Mortal Crit',             '+1.2% Critical Strike'),
(12,33,4,6,2, 3,  2.0,'Warmaster Endurance',     '+2.0% Stamina');

-- ============================================================
-- BOARD 13 — Fury: Bloodrage  (Attack Power%, Strength%)
-- ============================================================
INSERT IGNORE INTO `paragon_board_nodes`
  (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(13, 1,3,3,4, 0,  0.0,'The Bloodrage Path',      'Rage is your armor. Fury is your blade.'),
(13, 2,3,1,1,10,135.0,'Whirlwind Power',         '+135 Attack Power'),
(13, 3,2,2,1, 1,142.0,'Berserker Strength',      '+142 Strength'),
(13, 4,3,2,3, 0,  0.0,'Glyph Socket',            'Socket a Glyph.'),
(13, 5,4,2,1,10,135.0,'Bloodthirst Power',       '+135 Attack Power'),
(13, 6,2,3,1, 1,142.0,'Titan Grip Strength',     '+142 Strength'),
(13, 7,4,3,1,10,135.0,'Raging Blow Power',       '+135 Attack Power'),
(13, 8,2,4,1, 3,115.0,'Fury Endurance',          '+115 Stamina'),
(13, 9,3,4,3, 0,  0.0,'Glyph Socket',            'Socket a Glyph.'),
(13,10,4,4,1, 1,142.0,'Dual Wield Mastery',      '+142 Strength'),
(13,11,3,5,1,10,135.0,'Heroic Fury Power',       '+135 Attack Power'),
(13,12,1,1,0,10, 60.0,'Flurry AP',               '+60 Attack Power'),
(13,13,2,1,0, 1, 66.0,'Bloodthirst Muscle',      '+66 Strength'),
(13,14,4,1,0,10, 60.0,'Rampage AP',              '+60 Attack Power'),
(13,15,5,1,0, 3, 52.0,'Berserker Endurance',     '+52 Stamina'),
(13,16,1,2,0, 1, 66.0,'Endless Rage',            '+66 Strength'),
(13,17,5,2,0,10, 60.0,'Meat Cleaver AP',         '+60 Attack Power'),
(13,18,1,3,0,10, 60.0,'Wild Strike AP',          '+60 Attack Power'),
(13,19,5,3,0, 3, 52.0,'Battle Trance Body',      '+52 Stamina'),
(13,20,1,4,0, 1, 66.0,'Death Wish Strength',     '+66 Strength'),
(13,21,5,4,0,10, 60.0,'Execute Fury AP',         '+60 Attack Power'),
(13,22,1,5,0, 3, 52.0,'Furious Resolve Body',    '+52 Stamina'),
(13,23,2,5,0,10, 60.0,'Intensify Rage AP',       '+60 Attack Power'),
(13,24,4,5,0, 1, 66.0,'Unbridled Wrath',         '+66 Strength'),
(13,25,5,5,0,10, 60.0,'Bloodsurge AP',           '+60 Attack Power'),
(13,26,2,0,2,10,  2.5,'Fury Surge',              '+2.5% Attack Power'),
(13,27,4,0,2, 1,  2.5,'Colossus Fury',           '+2.5% Strength'),
(13,28,0,2,2, 8,  1.2,'Bloodrage Tempo',         '+1.2% Haste'),
(13,29,6,2,2,10,  2.5,'Whirlwind Surge',         '+2.5% Attack Power'),
(13,30,0,4,2, 8,  1.2,'Heroic Fury Speed',       '+1.2% Haste'),
(13,31,6,4,2,10,  2.5,'Bloodthirst Surge',       '+2.5% Attack Power'),
(13,32,2,6,2, 7,  1.2,'Fury Crit',               '+1.2% Critical Strike'),
(13,33,4,6,2, 3,  2.0,'Berserker Endurance',     '+2.0% Stamina');

-- ============================================================
-- BOARD 14 — Protection: Bulwark  (Stamina%, Armor%)
-- ============================================================
INSERT IGNORE INTO `paragon_board_nodes`
  (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(14, 1,3,3,4, 0,  0.0,'The Bulwark',             'An immovable wall of iron and will.'),
(14, 2,3,1,1, 3,138.0,'Bastion Stamina',         '+138 Stamina'),
(14, 3,2,2,1, 6,128.0,'Fortified Armor',         '+128 Armor'),
(14, 4,3,2,3, 0,  0.0,'Glyph Socket',            'Socket a Glyph.'),
(14, 5,4,2,1, 1,135.0,'Shield Wall Strength',    '+135 Strength'),
(14, 6,2,3,1, 3,138.0,'Last Stand Body',         '+138 Stamina'),
(14, 7,4,3,1, 6,128.0,'Devastate Plating',       '+128 Armor'),
(14, 8,2,4,1, 3,138.0,'Vigilance Body',          '+138 Stamina'),
(14, 9,3,4,3, 0,  0.0,'Glyph Socket',            'Socket a Glyph.'),
(14,10,4,4,1, 1,135.0,'Revenge Strength',        '+135 Strength'),
(14,11,3,5,1, 3,138.0,'Indomitable Body',        '+138 Stamina'),
(14,12,1,1,0, 3, 65.0,'Iron Flesh',              '+65 Stamina'),
(14,13,2,1,0, 6, 58.0,'Bulwark Plating',         '+58 Armor'),
(14,14,4,1,0, 3, 65.0,'Shield Block Body',       '+65 Stamina'),
(14,15,5,1,0, 1, 60.0,'Protector Strength',      '+60 Strength'),
(14,16,1,2,0, 6, 58.0,'Toughness Armor',         '+58 Armor'),
(14,17,5,2,0, 3, 65.0,'Warbringer Body',         '+65 Stamina'),
(14,18,1,3,0, 3, 65.0,'Shield Slam Body',        '+65 Stamina'),
(14,19,5,3,0, 6, 58.0,'Improved Defensive Stance','+58 Armor'),
(14,20,1,4,0, 1, 60.0,'Concussion Blow Strength','+60 Strength'),
(14,21,5,4,0, 3, 65.0,'Safeguard Body',          '+65 Stamina'),
(14,22,1,5,0, 6, 58.0,'Warbringer Plating',      '+58 Armor'),
(14,23,2,5,0, 3, 65.0,'Shockwave Body',          '+65 Stamina'),
(14,24,4,5,0, 1, 60.0,'Sword and Board Might',   '+60 Strength'),
(14,25,5,5,0, 3, 65.0,'Unending Resolve Body',   '+65 Stamina'),
(14,26,2,0,2, 3,  2.5,'Colossus Reserve',        '+2.5% Stamina'),
(14,27,4,0,2, 6,  2.0,'Iron Fortress',           '+2.0% Armor'),
(14,28,0,2,2, 3,  2.5,'Last Stand Reserve',      '+2.5% Stamina'),
(14,29,6,2,2, 6,  2.0,'Shield Wall Plating',     '+2.0% Armor'),
(14,30,0,4,2, 1,  2.0,'Prot Warrior Might',      '+2.0% Strength'),
(14,31,6,4,2, 3,  2.5,'Unbreakable Body',        '+2.5% Stamina'),
(14,32,2,6,2, 7,  0.8,'Devastate Crit',          '+0.8% Critical Strike'),
(14,33,4,6,2, 6,  2.0,'Fortress Armor',          '+2.0% Armor');

-- ============================================================
-- BOARD 15 — Holy: Radiance  (Spell Power%, Spirit%)
-- Paladin spec — requires board 3 at Paragon 100
-- ============================================================
INSERT IGNORE INTO `paragon_board_nodes`
  (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(15, 1,3,3,4, 0,  0.0,'The Holy Radiance',       'Healing light flows without limit.'),
(15, 2,3,1,1, 9,132.0,'Holy Light Power',        '+132 Spell Power'),
(15, 3,2,2,1, 4,128.0,'Radiance Mind',           '+128 Intellect'),
(15, 4,3,2,3, 0,  0.0,'Glyph Socket',            'Socket a Glyph.'),
(15, 5,4,2,1, 5,122.0,'Beacon of Light Spirit',  '+122 Spirit'),
(15, 6,2,3,1, 9,132.0,'Flash of Light Power',    '+132 Spell Power'),
(15, 7,4,3,1, 4,128.0,'Holy Shock Mind',         '+128 Intellect'),
(15, 8,2,4,1, 5,122.0,'Divine Illumination',     '+122 Spirit'),
(15, 9,3,4,3, 0,  0.0,'Glyph Socket',            'Socket a Glyph.'),
(15,10,4,4,1, 9,132.0,'Divine Plea Power',       '+132 Spell Power'),
(15,11,3,5,1, 4,128.0,'Judgement of Light Mind', '+128 Intellect'),
(15,12,1,1,0, 9, 60.0,'Lay on Hands Power',      '+60 Spell Power'),
(15,13,2,1,0, 5, 56.0,'Sanctified Light Spirit', '+56 Spirit'),
(15,14,4,1,0, 4, 58.0,'Holy Radiance Mind',      '+58 Intellect'),
(15,15,5,1,0, 3, 44.0,'Holy Body',               '+44 Stamina'),
(15,16,1,2,0, 5, 56.0,'Aura Mastery Spirit',     '+56 Spirit'),
(15,17,5,2,0, 9, 60.0,'Infusion of Light',       '+60 Spell Power'),
(15,18,1,3,0, 4, 58.0,'Sacred Cleansing Mind',   '+58 Intellect'),
(15,19,5,3,0, 5, 56.0,'Pure of Heart Spirit',    '+56 Spirit'),
(15,20,1,4,0, 9, 60.0,'Light of Dawn Power',     '+60 Spell Power'),
(15,21,5,4,0, 4, 58.0,'Enlightened Judgement',   '+58 Intellect'),
(15,22,1,5,0, 3, 44.0,'Holy Paladin Body',       '+44 Stamina'),
(15,23,2,5,0, 9, 60.0,'Divine Favor Power',      '+60 Spell Power'),
(15,24,4,5,0, 5, 56.0,'Tower of Radiance Spirit','+56 Spirit'),
(15,25,5,5,0, 4, 58.0,'Seal of Light Mind',      '+58 Intellect'),
(15,26,2,0,2, 9,  2.0,'Holy Radiance Surge',     '+2.0% Spell Power'),
(15,27,4,0,2, 5,  2.0,'Beacon Spirit',           '+2.0% Spirit'),
(15,28,0,2,2, 4,  2.0,'Luminous Intellect',      '+2.0% Intellect'),
(15,29,6,2,2, 9,  2.0,'Holy Light Surge',        '+2.0% Spell Power'),
(15,30,0,4,2, 8,  0.8,'Holy Tempo',              '+0.8% Haste'),
(15,31,6,4,2, 5,  2.0,'River of Light Spirit',   '+2.0% Spirit'),
(15,32,2,6,2, 7,  0.8,'Holy Crit',               '+0.8% Critical Strike'),
(15,33,4,6,2, 3,  2.0,'Holy Paladin Endurance',  '+2.0% Stamina');

-- ============================================================
-- BOARD 16 — Protection: Aegis  (Stamina%, Armor%)
-- Paladin spec — requires board 3 at Paragon 100
-- ============================================================
INSERT IGNORE INTO `paragon_board_nodes`
  (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(16, 1,3,3,4, 0,  0.0,'The Aegis',               'Your shield is your faith made solid.'),
(16, 2,3,1,1, 3,136.0,'Sacred Shield Body',      '+136 Stamina'),
(16, 3,2,2,1, 6,126.0,'Holy Aegis Plating',      '+126 Armor'),
(16, 4,3,2,3, 0,  0.0,'Glyph Socket',            'Socket a Glyph.'),
(16, 5,4,2,1, 1,132.0,'Hammer of Righteous Might','+132 Strength'),
(16, 6,2,3,1, 3,136.0,'Divine Guardian Body',    '+136 Stamina'),
(16, 7,4,3,1, 6,126.0,'Ardent Defender Plating', '+126 Armor'),
(16, 8,2,4,1, 3,136.0,'Avenger Shield Body',     '+136 Stamina'),
(16, 9,3,4,3, 0,  0.0,'Glyph Socket',            'Socket a Glyph.'),
(16,10,4,4,1, 1,132.0,'Judgement Strength',      '+132 Strength'),
(16,11,3,5,1, 3,136.0,'Light of the Eternal',    '+136 Stamina'),
(16,12,1,1,0, 3, 64.0,'Prot Paladin Body',       '+64 Stamina'),
(16,13,2,1,0, 6, 56.0,'Aegis Plating',           '+56 Armor'),
(16,14,4,1,0, 3, 64.0,'Sacred Ground Body',      '+64 Stamina'),
(16,15,5,1,0, 1, 60.0,'Crusader Might',          '+60 Strength'),
(16,16,1,2,0, 6, 56.0,'Guarded by the Light',    '+56 Armor'),
(16,17,5,2,0, 3, 64.0,'Righteous Fury Body',     '+64 Stamina'),
(16,18,1,3,0, 3, 64.0,'Shield of Righteousness', '+64 Stamina'),
(16,19,5,3,0, 6, 56.0,'Improved Devotion Aura',  '+56 Armor'),
(16,20,1,4,0, 1, 60.0,'Consecration Might',      '+60 Strength'),
(16,21,5,4,0, 3, 64.0,'Sanctuary Body',          '+64 Stamina'),
(16,22,1,5,0, 6, 56.0,'Touched by the Light',    '+56 Armor'),
(16,23,2,5,0, 3, 64.0,'Tower of Light Body',     '+64 Stamina'),
(16,24,4,5,0, 1, 60.0,'Seals of the Pure Might', '+60 Strength'),
(16,25,5,5,0, 3, 64.0,'Unbreakable Resolve',     '+64 Stamina'),
(16,26,2,0,2, 3,  2.5,'Aegis Endurance',         '+2.5% Stamina'),
(16,27,4,0,2, 6,  2.0,'Fortress of Faith',       '+2.0% Armor'),
(16,28,0,2,2, 3,  2.5,'Holy Light Reserve',      '+2.5% Stamina'),
(16,29,6,2,2, 6,  2.0,'Divine Plating',          '+2.0% Armor'),
(16,30,0,4,2, 1,  2.0,'Prot Paladin Might',      '+2.0% Strength'),
(16,31,6,4,2, 3,  2.5,'Aegis Constitution',      '+2.5% Stamina'),
(16,32,2,6,2, 7,  0.8,'Hammer Crit',             '+0.8% Critical Strike'),
(16,33,4,6,2, 6,  2.0,'Sacred Plating',          '+2.0% Armor');

-- ============================================================
-- BOARD 17 — Retribution: Crusade — COMPLETE (nodes 1-28)
-- The file already contains nodes 29-33. This adds the rest.
-- ============================================================
INSERT IGNORE INTO `paragon_board_nodes`
  (board_id,node_id,x,y,node_type,stat_type,stat_value,name,description) VALUES
(17, 1,3,3,4, 0,  0.0,'The Crusade',             'Strike with the full weight of the Light.'),
(17, 2,3,1,1, 1,138.0,'Templar Strength',        '+138 Strength'),
(17, 3,2,2,1,10,128.0,'Crusader Strike Power',   '+128 Attack Power'),
(17, 4,3,2,3, 0,  0.0,'Glyph Socket',            'Socket a Glyph.'),
(17, 5,4,2,1, 1,138.0,'Divine Storm Strength',   '+138 Strength'),
(17, 6,2,3,1,10,128.0,'Judgement Power',         '+128 Attack Power'),
(17, 7,4,3,1, 1,138.0,'Art of War Strength',     '+138 Strength'),
(17, 8,2,4,1, 3,114.0,'Retribution Body',        '+114 Stamina'),
(17, 9,3,4,3, 0,  0.0,'Glyph Socket',            'Socket a Glyph.'),
(17,10,4,4,1,10,128.0,'Exorcism Power',          '+128 Attack Power'),
(17,11,3,5,1, 1,138.0,'Hammer of Wrath Might',   '+138 Strength'),
(17,12,1,1,0, 1, 64.0,'Righteous Strength',      '+64 Strength'),
(17,13,2,1,0,10, 58.0,'Seal of Command AP',      '+58 Attack Power'),
(17,14,4,1,0, 1, 64.0,'Crusader Strength',       '+64 Strength'),
(17,15,5,1,0, 3, 50.0,'Ret Grit',                '+50 Stamina'),
(17,16,1,2,0,10, 58.0,'Sanctified Wrath AP',     '+58 Attack Power'),
(17,17,5,2,0, 1, 64.0,'Zealotry Strength',       '+64 Strength'),
(17,18,1,3,0, 1, 64.0,'Vengeance Strength',      '+64 Strength'),
(17,19,5,3,0, 3, 50.0,'Ret Paladin Body',        '+50 Stamina'),
(17,20,1,4,0,10, 58.0,'Sheath of Light AP',      '+58 Attack Power'),
(17,21,5,4,0, 1, 64.0,'Swift Retribution',       '+64 Strength'),
(17,22,1,5,0, 3, 50.0,'Pursuit of Justice Body', '+50 Stamina'),
(17,23,2,5,0, 1, 64.0,'Seal of Blood Strength',  '+64 Strength'),
(17,24,4,5,0,10, 58.0,'Divine Purpose AP',       '+58 Attack Power'),
(17,25,5,5,0, 1, 64.0,'Final Verdict Might',     '+64 Strength'),
(17,26,2,0,2, 1,  2.5,'Righteous Might',         '+2.5% Strength'),
(17,27,4,0,2,10,  2.5,'Crusader Power',          '+2.5% Attack Power'),
(17,28,0,2,2, 1,  2.5,'Holy Champion Might',     '+2.5% Strength');
-- Note: nodes 29-33 already exist in paragon_world.sql

SELECT 'Missing spec board nodes inserted (boards 12-17).' AS Status;
