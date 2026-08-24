-- Remove 50 inert Outland resource-rotation child-pool shells.
-- No physical gameobject spawn is removed. Every deletion is guarded so a
-- pool is preserved if a member or child relation has appeared meanwhile.

START TRANSACTION;

DELETE `pp`
FROM `pool_pool` AS `pp`
LEFT JOIN `pool_creature` AS `pc` ON `pc`.`pool_entry` = `pp`.`pool_id`
LEFT JOIN `pool_gameobject` AS `pg` ON `pg`.`pool_entry` = `pp`.`pool_id`
LEFT JOIN `pool_quest` AS `pq` ON `pq`.`pool_entry` = `pp`.`pool_id`
LEFT JOIN `game_event_pool` AS `gep` ON `gep`.`pool_entry` = `pp`.`pool_id`
LEFT JOIN `pool_pool` AS `child` ON `child`.`mother_pool` = `pp`.`pool_id`
WHERE `pp`.`pool_id` IN
(1361,1365,1366,1367,1368,1369,1370,1371,1372,1373,1374,1375,1376,1377,
 1378,1379,1380,1381,1382,1383,1385,1386,1387,1388,1389,1390,1391,1392,
 1393,1394,1395,1396,1397,1398,1399,1400,1401,1403,1404,1405,1406,1407,
 1408,1409,1410,1411,1412,1413,1414,1415)
AND `pc`.`guid` IS NULL
AND `pg`.`guid` IS NULL
AND `pq`.`entry` IS NULL
AND `gep`.`pool_entry` IS NULL
AND `child`.`pool_id` IS NULL;

DELETE `pt`
FROM `pool_template` AS `pt`
LEFT JOIN `pool_creature` AS `pc` ON `pc`.`pool_entry` = `pt`.`entry`
LEFT JOIN `pool_gameobject` AS `pg` ON `pg`.`pool_entry` = `pt`.`entry`
LEFT JOIN `pool_quest` AS `pq` ON `pq`.`pool_entry` = `pt`.`entry`
LEFT JOIN `game_event_pool` AS `gep` ON `gep`.`pool_entry` = `pt`.`entry`
LEFT JOIN `pool_pool` AS `pp_child` ON `pp_child`.`pool_id` = `pt`.`entry`
LEFT JOIN `pool_pool` AS `pp_mother` ON `pp_mother`.`mother_pool` = `pt`.`entry`
WHERE `pt`.`entry` IN
(1361,1365,1366,1367,1368,1369,1370,1371,1372,1373,1374,1375,1376,1377,
 1378,1379,1380,1381,1382,1383,1385,1386,1387,1388,1389,1390,1391,1392,
 1393,1394,1395,1396,1397,1398,1399,1400,1401,1403,1404,1405,1406,1407,
 1408,1409,1410,1411,1412,1413,1414,1415)
AND `pc`.`guid` IS NULL
AND `pg`.`guid` IS NULL
AND `pq`.`entry` IS NULL
AND `gep`.`pool_entry` IS NULL
AND `pp_child`.`pool_id` IS NULL
AND `pp_mother`.`pool_id` IS NULL;

COMMIT;
