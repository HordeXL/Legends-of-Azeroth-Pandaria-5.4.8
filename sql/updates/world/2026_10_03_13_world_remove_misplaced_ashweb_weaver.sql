-- Ashweb Weaver 58588 belongs in Guo-Lai Halls. Spawn 527500 was the only
-- Ashweb Weaver placed in Klaxxi'vess in the Dread Wastes.

START TRANSACTION;

DELETE FROM `creature_addon`
WHERE `guid`=527500;

DELETE FROM `pool_creature`
WHERE `guid`=527500;

DELETE FROM `creature_formations`
WHERE `memberGUID`=527500 OR `leaderGUID`=527500;

DELETE FROM `linked_respawn`
WHERE `guid`=527500 OR `linkedGuid`=527500;

DELETE FROM `creature`
WHERE `guid`=527500 AND `id`=58588;

COMMIT;
