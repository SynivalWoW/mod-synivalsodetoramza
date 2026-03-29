/*                                                                                         
This SQL script is part of the mod-Faction-Free AzerothCore module hosted at:              
https://github.com/gitdalisar/mod-Faction-Free                                             
                                                                                           
Maintained by GitDalisar                                                                   
                                                                                           
For Manual installation:                                                                   
1. Ensure that you are logged into MySQL Database                                          
2. Change to the acore_world database with:  USE acore_world;                              
3. Run this using this command: SOURCE <path to .sql>;                                     
                                                                                           
Version Change Log:                                                                        
Version 1.0.0:                                                                             
--Update quest_template to allow all factions to have access to all quests                 
Version 1.1.0:                                                                             
--Update areatrigger_tavern to allow all Inns to give rest xp bonus to all factions        
--Update plareycreateinfo_skills to allow all races to know all languages                  
--Update broadcast_text, creature_text, and npc_text to allow all players to read all npc c
--Update item_template to allow for all equipment to be used by all races and both factions
--Update broadcast_text, npc_text, creature_template, gameobject_template, creature, gameob
Version 1.3.0:                                                                             
--Update creature_template where Horde Factions that were still attacking Alliance to be se
--Update creature_template where Alliance Factions that were still attacking Horde to be se
--Update creature_template for Duskwood Nightwatch to single faction that appears to be pas
--Update creature_template for Enemy NPCs created during airship fight in ICC to an attacka
Version 1.3.1:                                                                             
--Update creature_template for another set of Horde/Alliance factions to Orgrimmar/Stormwin
Version 1.3.2:                                                                             
--Update creature_template to set Duskwood Nightwatch to Stormwind as both factions have a 
--Update item_template to get all items available to all races and factions as some were mi
--Update creature_template to set NPCs to attackable for The Battered Hilt quest chain     
--Added DELETE statements ahead of INSERT statements to allow this script to be ran cleanly
Version 1.3.4:                                                                             
--Update creature_template to set Raventusk Village to Orgrimmar as that attacked Alliance 
Version 1.3.5:                                                                             
--Update the INSERTS for the creature templates for the NPCs used for flight paths to no lo
Version 1.3.6:                                                                             
--Added 1637 to Horde list of factions still attacking Alliance Players within Silvermoon t
*/                                                                                         
                                                                                           
/*This will update the quest_template table to allow all races to have access to all quests
USE acpb_world;                                                                            
UPDATE `acore_world`.`quest_template` SET `AllowableRaces` = 1791 WHERE `AllowableRaces` = 
                                                                                           
/*This will update all Inns to give rested xp bonus to players regaurdless to the faction o
UPDATE `acore_world`.`areatrigger_tavern` SET `faction` = 6 WHERE `faction` != 6;          
                                                                                           
/*This will update the playercreateinfo_skills table to have all players start with knowing
UPDATE `acore_world`.`playercreateinfo_skills` SET `raceMask`=1791 WHERE `raceMask`!=1791 A
                                                                                           
/*This will update the broadcast_text, creature_text, and npc_text tables to ensure players
UPDATE `acore_world`.`broadcast_text` SET `LanguageID` = 0 WHERE `LanguageID` IN (1,2,3,6,7
UPDATE `acore_world`.`creature_text` SET `Language` = 0 WHERE `Language` IN (1,2,3,6,7,10,1
UPDATE `acore_world`.`npc_text` SET `lang0` = 0 WHERE `lang0` IN (1,2,3,6,7,10,13,14,33,35)
UPDATE `acore_world`.`npc_text` SET `lang1` = 0 WHERE `lang1` IN (1,2,3,6,7,10,13,14,33,35)
UPDATE `acore_world`.`npc_text` SET `lang2` = 0 WHERE `lang2` IN (1,2,3,6,7,10,13,14,33,35)
UPDATE `acore_world`.`npc_text` SET `lang3` = 0 WHERE `lang3` IN (1,2,3,6,7,10,13,14,33,35)
UPDATE `acore_world`.`npc_text` SET `lang4` = 0 WHERE `lang4` IN (1,2,3,6,7,10,13,14,33,35)
UPDATE `acore_world`.`npc_text` SET `lang5` = 0 WHERE `lang5` IN (1,2,3,6,7,10,13,14,33,35)
UPDATE `acore_world`.`npc_text` SET `lang6` = 0 WHERE `lang6` IN (1,2,3,6,7,10,13,14,33,35)
UPDATE `acore_world`.`npc_text` SET `lang7` = 0 WHERE `lang7` IN (1,2,3,6,7,10,13,14,33,35)
                                                                                           
/*This will update the item_template table to ensure all items that are faction locked are 
both cross-faction mount aquisition as well as faction specific quest drops since all quest
UPDATE `acore_world`.`item_template` SET `FlagsExtra` = 0 WHERE `FlagsExtra` IN (1, 2);    
UPDATE `acore_world`.`item_template` SET `FlagsExtra` = 8192 WHERE `FlagsExtra` IN (8193, 8
UPDATE `acore_world`.`item_template` SET `AllowableRace` = -1;                             
                                                                                           
/*This adds the broadcast_text and npc_text required for the two NPC that will teleport pla
npc_text and broacast_text line up using 500000 and 500001, with both using 500003 for subm
within your environment, you can change those values here.*/                               
DELETE FROM `acore_world`.`broadcast_text` WHERE `ID` IN (500000, 500001, 500003);         
DELETE FROM `acore_world`.`npc_text` WHERE `ID` IN (500000, 500001, 500003);               
INSERT INTO `acore_world`.`broadcast_text` (`ID`, `LanguageID`, `MaleText`, `FemaleText`, `
INSERT INTO `acore_world`.`broadcast_text` (`ID`, `LanguageID`, `MaleText`, `FemaleText`, `
INSERT INTO `acore_world`.`broadcast_text` (`ID`, `LanguageID`, `MaleText`, `FemaleText`, `
INSERT INTO `acore_world`.`npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang
INSERT INTO `acore_world`.`npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang
INSERT INTO `acore_world`.`npc_text` (`ID`, `text0_0`, `text0_1`, `BroadcastTextID0`, `lang
                                                                                           
/*This will create the two NPC used for the teleport network to aide in travel around the w
may have fewer cities or flight paths. They will use entry 500000 and 500001. If these are 
you can change those values here.*/                                                        
DELETE FROM `acore_world`.`creature_template` WHERE `entry` BETWEEN 500000 AND 500001;     
INSERT INTO `acore_world`.`creature_template` (`entry`, `difficulty_entry_1`, `difficulty_e
INSERT INTO `acore_world`.`creature_template` (`entry`, `difficulty_entry_1`, `difficulty_e
                                                                                           
/*This will create a series of objects in gameobject_template that were used to add astheti
other than just to make the area stand out and look better. They will use entry 500000-5000
environment, you can change those values here.*/                                           
DELETE FROM `acore_world`.`gameobject_template` WHERE `entry` BETWEEN 500000 AND 500004;   
INSERT INTO `acore_world`.`gameobject_template` (`entry`, `type`, `displayId`, `name`, `Ico
INSERT INTO `acore_world`.`gameobject_template` (`entry`, `type`, `displayId`, `name`, `Ico
INSERT INTO `acore_world`.`gameobject_template` (`entry`, `type`, `displayId`, `name`, `Ico
INSERT INTO `acore_world`.`gameobject_template` (`entry`, `type`, `displayId`, `name`, `Ico
INSERT INTO `acore_world`.`gameobject_template` (`entry`, `type`, `displayId`, `name`, `Ico
                                                                                           
/*This will insert all of the NPC creatures into the appropriate locations within the creat
500000000-500000019. If If these are already in use within your environment, you can change
DELETE FROM `acore_world`.`creature` WHERE `guid` BETWEEN 5000000 AND 5000019;             
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
INSERT INTO `acore_world`.`creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId
                                                                                           
/*This will insert all of the teleporter game objects into the appropriate locations within
500000000-500000049. If If these are already in use within your environment, you can change
DELETE FROM `acore_world`.`gameobject` WHERE `guid` BETWEEN 5000000 AND 5000049;           
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
INSERT INTO `acore_world`.`gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask
                                                                                           
/*This will modify Horde Factions that were still attacking Alliance players despite being 
UPDATE `creature_template` SET faction = 85 WHERE faction IN (83, 1734, 106, 1735, 1495, 16
                                                                                           
/*This will modify Alliance Factions that were still attacking Horde players despite being 
UPDATE `creature_template` SET faction = 11 WHERE faction IN (53, 56, 84, 1733, 210, 1732);
                                                                                           
/*This will modify the faction of all Enemy NPC created during the airship fight in ICC to 
UPDATE `creature_template` SET faction = 14 WHERE entry IN (36950,38406,38685,38686,36957,3
                                                                                           
/*This will modify the faction of the two NPCs, Sunreaver and Silver Covenant Agents, requi
UPDATE `acore_world`.`creature_template` SET `faction` = 7 WHERE `entry` IN (36776, 36774);
