-- Remove fully orphaned GUID 10011 references from the base dump.
-- There is no creature spawn with GUID 10011. The linked-respawn master
-- 136105 is Lady Deathwhisper (entry 36855); keep all of her valid links.

DELETE `ca`
FROM `creature_addon` AS `ca`
WHERE `ca`.`guid` = 10011
  AND `ca`.`path_id` = 136105
  AND NOT EXISTS
      (SELECT 1 FROM `creature` AS `c` WHERE `c`.`guid` = `ca`.`guid`)
  AND NOT EXISTS
      (SELECT 1 FROM `waypoint_data` AS `wp` WHERE `wp`.`id` = `ca`.`path_id`);

DELETE `lr`
FROM `linked_respawn` AS `lr`
WHERE `lr`.`guid` = 10011
  AND `lr`.`linkedGuid` = 136105
  AND `lr`.`linkType` = 0
  AND NOT EXISTS
      (SELECT 1 FROM `creature` AS `slave` WHERE `slave`.`guid` = `lr`.`guid`)
  AND EXISTS
      (SELECT 1
       FROM `creature` AS `master`
       WHERE `master`.`guid` = `lr`.`linkedGuid`
         AND `master`.`id` = 36855
         AND `master`.`map` = 631);
