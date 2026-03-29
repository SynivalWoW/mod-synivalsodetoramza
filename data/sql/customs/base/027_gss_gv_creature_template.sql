-- ============================================================
-- mod-synival-guild-sanctuary | customs database
-- ============================================================
-- Run against your CUSTOMS (world) database after the Guild Village
-- base SQL files (001-026_gv_*.sql) have been applied.
--
-- This file adds the Warden of the Vault (entry 501000) to the 'base'
-- layout so she automatically spawns inside every guild village when
-- the village is created or reloaded at server startup.
--
-- Coordinates: centred on the Azshara village zone near the other
-- vendor NPCs.  Adjust position_x/y/z/orientation to taste.
-- ============================================================

-- ── Add Warden to the village base creature layout ────────────────────────
-- gv_creature_template drives InstallBaseLayout() in guild_village_create.cpp.
-- layout_key = 'base' means she spawns in every new guild village.

DELETE FROM `customs`.`gv_creature_template`
    WHERE `entry` = 501000 AND `layout_key` = 'base';

INSERT INTO `customs`.`gv_creature_template` (
    `entry`,
    `layout_key`,
    `map`,
    `position_x`,
    `position_y`,
    `position_z`,
    `orientation`,
    `spawntimesecs`,
    `spawndist`,
    `movementtype`
) VALUES (
    501000,
    'base',
    37,             -- map 37 = Azshara (default guild village map)
    1034.52,        -- X — near the Runic Archive / Upgrade NPC cluster
    285.17,         -- Y
    332.66,         -- Z
    1.5708,         -- Orientation (facing South)
    300,            -- Respawn: 5 minutes
    0.0,            -- No wandering (Idle)
    0               -- MovementType 0 = Idle
);

-- ── Teleport menu entry: Vault Portal ─────────────────────────────────────
-- Adds a [Vault Portal] entry to the guild village in-village teleporter
-- (gv_teleport_menu) so players can quick-jump to the Warden.
-- expansion_required is blank so it shows from day one.

DELETE FROM `customs`.`gv_teleport_menu`
    WHERE `id` = 5010 AND `npc_entry` = 990203;

INSERT INTO `customs`.`gv_teleport_menu` (
    `id`,
    `npc_entry`,
    `label_cs`,
    `label_en`,
    `x`, `y`, `z`, `o`,
    `sort_index`,
    `expansion_required`
) VALUES (
    5010,           -- unique row ID — choose one that doesn't conflict
    990203,         -- GV_TELEPORTER_ENTRY (matches guild_village_teleporter.cpp)
    'Vault portál', -- Czech label
    'Vault Portal', -- English label
    1034.52,        -- Warden X
    285.17,         -- Warden Y
    332.66,         -- Warden Z
    1.5708,         -- Orientation
    90,             -- Sort order (high = near bottom of teleporter list)
    ''              -- No expansion required
);
