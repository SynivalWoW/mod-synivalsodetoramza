-- ============================================================
-- scriptname_patch.sql
-- Fixes the ScriptName on NPC 99996 (Runic Archive).
-- The old 'npc_runic_archive' C++ class was removed in Session 5.
-- The replacement lightweight class is 'npc_runic_archive_statsync'.
-- Without this patch, AzerothCore logs an error on every startup:
--   "Script 'npc_runic_archive' not found."
-- Run against acpb_world.
-- ============================================================
USE acpb_world;

UPDATE `creature_template`
SET    `ScriptName` = 'npc_runic_archive_statsync'
WHERE  `entry` = 99996;

SELECT ROW_COUNT() AS rows_updated;
