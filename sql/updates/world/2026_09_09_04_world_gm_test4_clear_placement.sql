-- Move only the four-target GM Island station out of the large tree.
-- Ground sampled from 0001_01_01.map. The pack and approach corridor,
-- including a 3-yard margin, are outside every model bound in its vmap tile.
-- Keep a 4-yard square and at least 45 yards from the other training dummies.
UPDATE `creature` c
JOIN (
    SELECT 4000110 AS `guid`, 16202.0 AS `x`, 16324.0 AS `y`, 18.3234 AS `z`
    UNION ALL SELECT 4000111, 16202.0, 16328.0, 17.9812
    UNION ALL SELECT 4000112, 16206.0, 16324.0, 18.2092
    UNION ALL SELECT 4000113, 16206.0, 16328.0, 18.4230
) p ON p.`guid` = c.`guid`
SET c.`position_x` = p.`x`, c.`position_y` = p.`y`,
    c.`position_z` = p.`z`, c.`orientation` = 4.712389
WHERE c.`id` = 70245 AND c.`map` = 1 AND c.`areaId` = 876;

UPDATE `game_tele`
SET `position_x` = 16204.0, `position_y` = 16314.0,
    `position_z` = 18.0373, `orientation` = 1.570796
WHERE `name` = 'GMTest4' AND `map` = 1;
