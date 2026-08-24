-- Restore authentic pool membership from the full SFDB 5.4.8 source.
-- Source GUIDs cannot be copied because this database converted/reused them;
-- each INSERT therefore selects the matching current spawn by exact GUID+entry.

START TRANSACTION;

-- Three Ethereum-prison gameobjects at each of seven source locations.
INSERT IGNORE INTO `pool_gameobject` (`guid`,`pool_entry`,`chance`,`description`)
SELECT `guid`,107,20,'' FROM `gameobject` WHERE `guid`=67410 AND `id`=182952;
INSERT IGNORE INTO `pool_gameobject` (`guid`,`pool_entry`,`chance`,`description`)
SELECT `guid`,107,0,'' FROM `gameobject` WHERE (`guid`,`id`) IN ((47476,182953),(3678,182954));

INSERT IGNORE INTO `pool_gameobject` (`guid`,`pool_entry`,`chance`,`description`)
SELECT `guid`,113,20,'' FROM `gameobject` WHERE `guid`=67416 AND `id`=182952;
INSERT IGNORE INTO `pool_gameobject` (`guid`,`pool_entry`,`chance`,`description`)
SELECT `guid`,113,0,'' FROM `gameobject` WHERE (`guid`,`id`) IN ((3908,182953),(3800,182954));

INSERT IGNORE INTO `pool_gameobject` (`guid`,`pool_entry`,`chance`,`description`)
SELECT `guid`,162,20,'' FROM `gameobject` WHERE `guid`=4112 AND `id`=182952;
INSERT IGNORE INTO `pool_gameobject` (`guid`,`pool_entry`,`chance`,`description`)
SELECT `guid`,162,0,'' FROM `gameobject` WHERE (`guid`,`id`) IN ((71115,182953),(3814,182954));

INSERT IGNORE INTO `pool_gameobject` (`guid`,`pool_entry`,`chance`,`description`)
SELECT `guid`,302,20,'' FROM `gameobject` WHERE `guid`=4049 AND `id`=182952;
INSERT IGNORE INTO `pool_gameobject` (`guid`,`pool_entry`,`chance`,`description`)
SELECT `guid`,302,0,'' FROM `gameobject` WHERE (`guid`,`id`) IN ((3982,182953),(3670,182954));

INSERT IGNORE INTO `pool_gameobject` (`guid`,`pool_entry`,`chance`,`description`)
SELECT `guid`,304,20,'' FROM `gameobject` WHERE `guid`=4051 AND `id`=182952;
INSERT IGNORE INTO `pool_gameobject` (`guid`,`pool_entry`,`chance`,`description`)
SELECT `guid`,304,0,'' FROM `gameobject` WHERE (`guid`,`id`) IN ((3882,182953),(15199,182954));

INSERT IGNORE INTO `pool_gameobject` (`guid`,`pool_entry`,`chance`,`description`)
SELECT `guid`,327,20,'' FROM `gameobject` WHERE `guid`=4160 AND `id`=182952;
INSERT IGNORE INTO `pool_gameobject` (`guid`,`pool_entry`,`chance`,`description`)
SELECT `guid`,327,0,'' FROM `gameobject` WHERE (`guid`,`id`) IN ((4020,182953),(3636,182954));

INSERT IGNORE INTO `pool_gameobject` (`guid`,`pool_entry`,`chance`,`description`)
SELECT `guid`,328,20,'' FROM `gameobject` WHERE `guid`=4166 AND `id`=182952;
INSERT IGNORE INTO `pool_gameobject` (`guid`,`pool_entry`,`chance`,`description`)
SELECT `guid`,328,0,'' FROM `gameobject` WHERE (`guid`,`id`) IN ((4022,182953),(3675,182954));

-- Grocklar: the six source positions exist under converted current GUIDs.
INSERT IGNORE INTO `pool_creature` (`guid`,`pool_entry`,`chance`,`description`)
SELECT `guid`,1095,0,CONCAT('Grocklar Spawnlocation ',
    CASE `guid` WHEN 64642 THEN 1 WHEN 64555 THEN 2 WHEN 64565 THEN 3
                WHEN 64595 THEN 4 WHEN 64576 THEN 5 WHEN 64598 THEN 6 END)
FROM `creature`
WHERE (`guid`,`id`) IN
((64642,32422),(64555,32422),(64565,32422),(64595,32422),(64576,32422),(64598,32422));

-- Correct descriptions/limits that were inherited from unrelated GUID-era data.
UPDATE `pool_template` SET `description`='' WHERE `entry` IN (107,113,162,302,304,327,328);
UPDATE `pool_template`
SET `max_limit`=1,`description`='Grocklar Rare Spawn (1 out 6)'
WHERE `entry`=1095;

COMMIT;
