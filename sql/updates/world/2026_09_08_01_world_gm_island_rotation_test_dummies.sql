-- GM Island only: isolated 4 / 1 / 3 target rotation test stations.
-- Reuse the attackable, high-health level-90 training dummy (70245).
-- Do not modify its shared template or any pre-existing world spawn.
-- Reserved spawn GUIDs: 4000110..4000117. Existing GUIDs are never overwritten.
-- Ground heights sampled from the local 5.4.8 map tile 0001_01_01.map.
-- Rerunning this migration does not duplicate spawns or teleport names.

INSERT INTO `creature`
    (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
     `position_x`, `position_y`, `position_z`, `orientation`,
     `spawntimesecs`, `wander_distance`, `MovementType`, `curhealth`, `curmana`)
SELECT p.`guid`, 70245, 1, 876, 876, 1, 1,
       p.`x`, p.`y`, p.`z`, 4.712389, 300, 0, 0, 0, 0
FROM (
    -- Four targets: 4-yard square, all within Seed range of each other.
    SELECT 4000110 AS `guid`, 16295.0 AS `x`, 16239.0 AS `y`, 24.8937 AS `z`
    UNION ALL SELECT 4000111, 16295.0, 16243.0, 24.9006
    UNION ALL SELECT 4000112, 16299.0, 16239.0, 25.0558
    UNION ALL SELECT 4000113, 16299.0, 16243.0, 24.9820
    -- One target, separated from both packs and the pre-existing raid dummy.
    UNION ALL SELECT 4000114, 16207.0, 16279.0, 12.0508
    -- Three targets: compact triangle for multidot/cleave tests.
    UNION ALL SELECT 4000115, 16256.0, 16332.0, 12.9411
    UNION ALL SELECT 4000116, 16260.0, 16332.0, 12.9498
    UNION ALL SELECT 4000117, 16258.0, 16336.0, 12.9419
) AS p
WHERE NOT EXISTS (SELECT 1 FROM `creature` c WHERE c.`guid` = p.`guid`)
  AND EXISTS (SELECT 1 FROM `creature_template` t WHERE t.`entry` = 70245
              AND t.`minlevel` = 90 AND t.`maxlevel` = 90
              AND t.`ScriptName` = 'npc_training_dummy');

INSERT INTO `game_tele` (`position_x`, `position_y`, `position_z`, `orientation`, `map`, `name`)
SELECT p.`x`, p.`y`, p.`z`, 1.570796, 1, p.`name`
FROM (
    SELECT 16297.0 AS `x`, 16229.0 AS `y`, 27.1049 AS `z`, 'GMTest4' AS `name`
    UNION ALL SELECT 16207.0, 16267.0, 13.7888, 'GMTest1'
    UNION ALL SELECT 16258.0, 16323.0, 13.0249, 'GMTest3'
) AS p
WHERE NOT EXISTS (SELECT 1 FROM `game_tele` t WHERE t.`name` = p.`name`);
