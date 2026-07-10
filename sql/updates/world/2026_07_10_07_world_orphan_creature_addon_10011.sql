-- Remove a fully orphaned creature_addon row from the base dump.
-- There is no creature spawn with GUID 10011 and path 136105 has no nodes.
-- Keep the row if either owner or movement data is restored before this runs.

DELETE `ca`
FROM `creature_addon` AS `ca`
WHERE `ca`.`guid` = 10011
  AND `ca`.`path_id` = 136105
  AND NOT EXISTS
      (SELECT 1 FROM `creature` AS `c` WHERE `c`.`guid` = `ca`.`guid`)
  AND NOT EXISTS
      (SELECT 1 FROM `waypoint_data` AS `wp` WHERE `wp`.`id` = `ca`.`path_id`);
