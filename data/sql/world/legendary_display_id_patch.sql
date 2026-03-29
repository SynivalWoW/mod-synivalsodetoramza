-- ============================================================
-- mod-synival-paragon | Legendary Item Display ID Update
-- Replaces placeholder display IDs with confirmed WotLK 3.3.5a
-- ICC / T10 era model IDs. Run against acpb_world.
-- Safe to re-run — all UPDATEs are idempotent.
-- ============================================================
USE acpb_world;

-- ── WARRIOR (99500-99505) ────────────────────────────────────
-- Weapon: Shadowmourne 2H axe (65153)
-- Head:   Faceguard of Wrath / Sanctified Scourgelord Helmet (62987)
-- Chest:  Blightborne Warplate / Scourgelord Battleplate (64584)
-- Hands:  Fleshrending Gauntlets (64571)
-- Legs:   Scourgelord Legplates (64595)
-- Feet:   Grinning Skull Greatboots (64789)
UPDATE `item_template` SET `displayid` = 65153 WHERE `entry` = 99500;
UPDATE `item_template` SET `displayid` = 62987 WHERE `entry` = 99501;
UPDATE `item_template` SET `displayid` = 64584 WHERE `entry` = 99502;
UPDATE `item_template` SET `displayid` = 64571 WHERE `entry` = 99503;
UPDATE `item_template` SET `displayid` = 64595 WHERE `entry` = 99504;
UPDATE `item_template` SET `displayid` = 64789 WHERE `entry` = 99505;

-- ── PALADIN (99506-99511) ────────────────────────────────────
-- Weapon: Hammer of Purified Flame (64954)
-- Head:   Lightsworn Helmet (64630)
-- Chest:  Lightsworn Battleplate (64637)
-- Hands:  Lightsworn Gauntlets (64627)
-- Legs:   Lightsworn Legplates (64633)
-- Feet:   Black Spire Sabatons / mail boots (64721)
UPDATE `item_template` SET `displayid` = 64954 WHERE `entry` = 99506;
UPDATE `item_template` SET `displayid` = 64630 WHERE `entry` = 99507;
UPDATE `item_template` SET `displayid` = 64637 WHERE `entry` = 99508;
UPDATE `item_template` SET `displayid` = 64627 WHERE `entry` = 99509;
UPDATE `item_template` SET `displayid` = 64633 WHERE `entry` = 99510;
UPDATE `item_template` SET `displayid` = 64721 WHERE `entry` = 99511;

-- ── HUNTER (99512-99517) ─────────────────────────────────────
-- Ranged: Crypt Fiend Slayer bow (64748)
-- Head:   Faceplate of the Forgotten — mail (64688)
-- Chest:  Mail of Crimson Coins (65039)
-- Hands:  Fleshrending Gauntlets — mail (64571)
-- Legs:   Legguards of the Frosty Depths — mail (64722)
-- Feet:   Black Spire Sabatons — mail (64721)
UPDATE `item_template` SET `displayid` = 64748 WHERE `entry` = 99512;
UPDATE `item_template` SET `displayid` = 64688 WHERE `entry` = 99513;
UPDATE `item_template` SET `displayid` = 65039 WHERE `entry` = 99514;
UPDATE `item_template` SET `displayid` = 64571 WHERE `entry` = 99515;
UPDATE `item_template` SET `displayid` = 64722 WHERE `entry` = 99516;
UPDATE `item_template` SET `displayid` = 64721 WHERE `entry` = 99517;

-- ── ROGUE (99518-99523) ──────────────────────────────────────
-- Weapon: Frozen Bonespike dagger (64646)
-- Head:   Shadowblade Helmet — leather (63690)
-- Chest:  Shadowblade Breastplate (63692)
-- Hands:  Shadowblade Gauntlets (63693)
-- Legs:   Shadowblade Legplates (63691)
-- Feet:   Mudslide Boots — leather (64665)
UPDATE `item_template` SET `displayid` = 64646 WHERE `entry` = 99518;
UPDATE `item_template` SET `displayid` = 63690 WHERE `entry` = 99519;
UPDATE `item_template` SET `displayid` = 63692 WHERE `entry` = 99520;
UPDATE `item_template` SET `displayid` = 63693 WHERE `entry` = 99521;
UPDATE `item_template` SET `displayid` = 63691 WHERE `entry` = 99522;
UPDATE `item_template` SET `displayid` = 64665 WHERE `entry` = 99523;

-- ── PRIEST (99524-99529) ─────────────────────────────────────
-- Weapon: Nibelung staff — holy/death motif (64342)
-- Head:   Crimson Acolyte Cowl — cloth (64258)
-- Chest:  Frostsworn Bone Chestpiece — cloth (64703)
-- Hands:  Crimson Acolyte Handwraps (64257)
-- Legs:   Crimson Acolyte Pants (64255)
-- Feet:   Icecrown Spire Sandals — cloth (64296)
UPDATE `item_template` SET `displayid` = 64342 WHERE `entry` = 99524;
UPDATE `item_template` SET `displayid` = 64258 WHERE `entry` = 99525;
UPDATE `item_template` SET `displayid` = 64703 WHERE `entry` = 99526;
UPDATE `item_template` SET `displayid` = 64257 WHERE `entry` = 99527;
UPDATE `item_template` SET `displayid` = 64255 WHERE `entry` = 99528;
UPDATE `item_template` SET `displayid` = 64296 WHERE `entry` = 99529;

-- ── DEATH KNIGHT (99530-99535) ───────────────────────────────
-- Weapon: Shadowmourne 2H axe (65153)
-- Head:   Scourgelord Helmet — plate (64594)
-- Chest:  Scourgelord Battleplate (64592)
-- Hands:  Scourgelord Gauntlets (64593)
-- Legs:   Scourgelord Legplates (64595)
-- Feet:   Hellfrozen Bonegrinders / Grinning Skull — plate (64789)
UPDATE `item_template` SET `displayid` = 65153 WHERE `entry` = 99530;
UPDATE `item_template` SET `displayid` = 64594 WHERE `entry` = 99531;
UPDATE `item_template` SET `displayid` = 64592 WHERE `entry` = 99532;
UPDATE `item_template` SET `displayid` = 64593 WHERE `entry` = 99533;
UPDATE `item_template` SET `displayid` = 64595 WHERE `entry` = 99534;
UPDATE `item_template` SET `displayid` = 64789 WHERE `entry` = 99535;

-- ── SHAMAN (99536-99541) ─────────────────────────────────────
-- Weapon: Dying Light staff — elemental (64337)
-- Head:   Faceplate of the Forgotten — mail (64688)
-- Chest:  Mail of Crimson Coins (65039)
-- Hands:  Fleshrending Gauntlets — mail (64571)
-- Legs:   Legguards of the Frosty Depths — mail (64722)
-- Feet:   Black Spire Sabatons — mail (64721)
UPDATE `item_template` SET `displayid` = 64337 WHERE `entry` = 99536;
UPDATE `item_template` SET `displayid` = 64688 WHERE `entry` = 99537;
UPDATE `item_template` SET `displayid` = 65039 WHERE `entry` = 99538;
UPDATE `item_template` SET `displayid` = 64571 WHERE `entry` = 99539;
UPDATE `item_template` SET `displayid` = 64722 WHERE `entry` = 99540;
UPDATE `item_template` SET `displayid` = 64721 WHERE `entry` = 99541;

-- ── MAGE (99542-99547) ───────────────────────────────────────
-- Weapon: Archus, Greatstaff of Antonidas (64334)
-- Head:   Dark Coven Hood — cloth dark/arcane (64286)
-- Chest:  Frostsworn Bone Chestpiece — cloth (64703)
-- Hands:  Dark Coven Gloves (64283)
-- Legs:   Dark Coven Leggings (64287)
-- Feet:   Icecrown Spire Sandals — cloth (64296)
UPDATE `item_template` SET `displayid` = 64334 WHERE `entry` = 99542;
UPDATE `item_template` SET `displayid` = 64286 WHERE `entry` = 99543;
UPDATE `item_template` SET `displayid` = 64703 WHERE `entry` = 99544;
UPDATE `item_template` SET `displayid` = 64283 WHERE `entry` = 99545;
UPDATE `item_template` SET `displayid` = 64287 WHERE `entry` = 99546;
UPDATE `item_template` SET `displayid` = 64296 WHERE `entry` = 99547;

-- ── WARLOCK (99548-99553) ────────────────────────────────────
-- Weapon: Engraved Gargoyle Femur staff — dark/fel (64762)
-- Head:   Bloodmage Hood — dark purple cloth (64892)
-- Chest:  Carapace of Forgotten Kings — dark leather/cloth (64828)
-- Hands:  Bloodmage Gloves (64267)
-- Legs:   Bloodmage Leggings (64269)
-- Feet:   Ice-Steeped Sandals — cloth (64579)
UPDATE `item_template` SET `displayid` = 64762 WHERE `entry` = 99548;
UPDATE `item_template` SET `displayid` = 64892 WHERE `entry` = 99549;
UPDATE `item_template` SET `displayid` = 64828 WHERE `entry` = 99550;
UPDATE `item_template` SET `displayid` = 64267 WHERE `entry` = 99551;
UPDATE `item_template` SET `displayid` = 64269 WHERE `entry` = 99552;
UPDATE `item_template` SET `displayid` = 64579 WHERE `entry` = 99553;

-- ── DRUID (99554-99559) ──────────────────────────────────────
-- Weapon: Dying Light staff — nature/balance (64337)
-- Head:   Lasherweave Helmet — leather (64446)
-- Chest:  Carapace of Forgotten Kings — leather (64828)
-- Hands:  Lasherweave Gauntlets (64448)
-- Legs:   Lasherweave Legplates (64458)
-- Feet:   Treads of the Wasteland — leather (64822)
UPDATE `item_template` SET `displayid` = 64337 WHERE `entry` = 99554;
UPDATE `item_template` SET `displayid` = 64446 WHERE `entry` = 99555;
UPDATE `item_template` SET `displayid` = 64828 WHERE `entry` = 99556;
UPDATE `item_template` SET `displayid` = 64448 WHERE `entry` = 99557;
UPDATE `item_template` SET `displayid` = 64458 WHERE `entry` = 99558;
UPDATE `item_template` SET `displayid` = 64822 WHERE `entry` = 99559;

SELECT CONCAT('Updated display IDs for ', COUNT(*), ' legendary items.')
  FROM `item_template`
  WHERE `entry` BETWEEN 99500 AND 99559;
