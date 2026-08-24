-- Remove unreachable waypoint scripts which have no waypoint_data caller.
--
-- The 46 script IDs contain 81 rows. IDs 57-95 partly use trinity_string
-- core/GM diagnostic messages as creature speech, while IDs 147-153 use
-- empty TALK text IDs. None is referenced by waypoint_data.action, and the
-- rows are absent from both the local SFDB 5.4.8 and TDB 4.3.4 sources.
-- The NOT EXISTS guard preserves a script if another update links it before
-- this migration is applied.

DELETE `ws`
FROM `waypoint_scripts` AS `ws`
WHERE (`ws`.`id` BETWEEN 57 AND 95 OR `ws`.`id` BETWEEN 147 AND 153)
  AND NOT EXISTS
  (
    SELECT 1
    FROM `waypoint_data` AS `wd`
    WHERE `wd`.`action` = `ws`.`id`
  );
