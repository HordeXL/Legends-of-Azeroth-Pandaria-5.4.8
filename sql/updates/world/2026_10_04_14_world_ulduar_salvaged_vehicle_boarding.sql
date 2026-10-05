-- Ulduar: Flame Leviathan salvaged vehicles (25-player normal).
-- Keep the retail gear-scaling ride spells used by mod-playerbots and ensure
-- the 25-player staging area has five of each main vehicle.

START TRANSACTION;

UPDATE `creature_template`
SET `npcflag` = `npcflag` | 16777216,
    `unit_flags` = `unit_flags` & 4261412863,
    `AIName` = '',
    `ScriptName` = 'npc_vehicle_ulduar'
WHERE `entry` IN (33060, 33062, 33109);

DELETE FROM `npc_spellclick_spells`
WHERE `npc_entry` IN (33060, 33062, 33109);

INSERT INTO `npc_spellclick_spells`
    (`npc_entry`, `spell_id`, `cast_flags`, `user_type`)
VALUES
    (33060, 65031, 1, 0), -- Salvaged Siege Engine: Ride Vehicle (scales with gear)
    (33062, 65030, 1, 0), -- Salvaged Chopper: Ride Vehicle (scales with gear)
    (33109, 62309, 1, 0); -- Salvaged Demolisher: Ride Vehicle (scales with gear)

-- The shared 10/25-player spawns provide two vehicles of each kind. Add the
-- other three only to 25-player normal (spawn mask 16).
INSERT INTO `creature`
    (`id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`,
     `orientation`, `spawntimesecs`, `curhealth`, `curmana`)
SELECT 33109, 603, 16, 65535, -781.448, -236.561, 432.227, 1.55975, 604800, 630000, 50
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `id` = 33109 AND `map` = 603 AND ABS(`position_x` + 781.448) < 0.01 AND ABS(`position_y` + 236.561) < 0.01);
INSERT INTO `creature` (`id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `curhealth`, `curmana`)
SELECT 33109, 603, 16, 65535, -803.834, -251.963, 432.502, 1.28483, 604800, 630000, 50
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `id` = 33109 AND `map` = 603 AND ABS(`position_x` + 803.834) < 0.01 AND ABS(`position_y` + 251.963) < 0.01);
INSERT INTO `creature` (`id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `curhealth`, `curmana`)
SELECT 33109, 603, 16, 65535, -753.779, -214.948, 430.857, 1.58724, 604800, 630000, 50
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `id` = 33109 AND `map` = 603 AND ABS(`position_x` + 753.779) < 0.01 AND ABS(`position_y` + 214.948) < 0.01);

INSERT INTO `creature` (`id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `curhealth`, `curmana`)
SELECT 33062, 603, 16, 65535, -718.173, -122.482, 430.143, 6.27999, 604800, 504000, 100
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `id` = 33062 AND `map` = 603 AND ABS(`position_x` + 718.173) < 0.01 AND ABS(`position_y` + 122.482) < 0.01);
INSERT INTO `creature` (`id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `curhealth`, `curmana`)
SELECT 33062, 603, 16, 65535, -717.931, -113.959, 430.188, 6.17003, 604800, 504000, 100
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `id` = 33062 AND `map` = 603 AND ABS(`position_x` + 717.931) < 0.01 AND ABS(`position_y` + 113.959) < 0.01);
INSERT INTO `creature` (`id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `curhealth`, `curmana`)
SELECT 33062, 603, 16, 65535, -717.602, -110.131, 430.101, 6.16218, 604800, 504000, 100
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `id` = 33062 AND `map` = 603 AND ABS(`position_x` + 717.602) < 0.01 AND ABS(`position_y` + 110.131) < 0.01);

INSERT INTO `creature` (`id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `curhealth`, `curmana`)
SELECT 33060, 603, 16, 65535, -754.373, -29.9551, 429.842, 4.99981, 604800, 1134000, 100
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `id` = 33060 AND `map` = 603 AND ABS(`position_x` + 754.373) < 0.01 AND ABS(`position_y` + 29.9551) < 0.01);
INSERT INTO `creature` (`id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `curhealth`, `curmana`)
SELECT 33060, 603, 16, 65535, -719.100, -18.4986, 429.841, 4.71314, 604800, 1134000, 100
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `id` = 33060 AND `map` = 603 AND ABS(`position_x` + 719.100) < 0.01 AND ABS(`position_y` + 18.4986) < 0.01);
INSERT INTO `creature` (`id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `curhealth`, `curmana`)
SELECT 33060, 603, 16, 65535, -815.958, -85.2015, 429.991, 6.27607, 604800, 1134000, 100
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `id` = 33060 AND `map` = 603 AND ABS(`position_x` + 815.958) < 0.01 AND ABS(`position_y` + 85.2015) < 0.01);

COMMIT;
