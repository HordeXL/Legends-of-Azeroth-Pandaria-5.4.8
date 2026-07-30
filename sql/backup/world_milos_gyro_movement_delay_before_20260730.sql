-- Exact rollback for
-- 2026_07_30_11_world_fix_milos_gyro_movement_delay.sql.
--
-- Remove only the exact added timed-action row, then restore the original
-- immediate waypoint-start action from its complete backup.

START TRANSACTION;

SET @milos_gyro_delay_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`entryorguid` = 37198
               AND `source_type` = 0
               AND `id` = 0
               AND `link` = 0
               AND `event_type` = 54
               AND `event_chance` = 100
               AND `action_type` = 53
               AND `action_param1` = 1
               AND `action_param2` = 37198
               AND `target_type` = 1) = 1
    FROM `_backup_smart_scripts_milos_gyro_delay_20260730`
);

DELETE FROM `smart_scripts`
WHERE @milos_gyro_delay_backup_ok = 1
  AND `entryorguid` = 3719800
  AND `source_type` = 9
  AND `id` = 0
  AND `link` = 0
  AND `event_type` = 0
  AND `event_phase_mask` = 0
  AND `event_chance` = 100
  AND `event_flags` = 0
  AND `event_param1` = 1000
  AND `event_param2` = 1000
  AND `action_type` = 53
  AND `action_param1` = 1
  AND `action_param2` = 37198
  AND `target_type` = 1
  AND `comment` =
      'Milo''s Gyro - On Script - Start waypoint movement after 1 second';

UPDATE `smart_scripts` AS `target`
INNER JOIN `_backup_smart_scripts_milos_gyro_delay_20260730` AS `backup`
    ON `backup`.`entryorguid` = `target`.`entryorguid`
   AND `backup`.`source_type` = `target`.`source_type`
   AND `backup`.`id` = `target`.`id`
   AND `backup`.`link` = `target`.`link`
SET
    `target`.`action_type` = `backup`.`action_type`,
    `target`.`action_param1` = `backup`.`action_param1`,
    `target`.`action_param2` = `backup`.`action_param2`,
    `target`.`comment` = `backup`.`comment`
WHERE @milos_gyro_delay_backup_ok = 1
  AND `target`.`entryorguid` = 37198
  AND `target`.`source_type` = 0
  AND `target`.`id` = 0
  AND `target`.`link` = 0
  AND `target`.`event_type` = 54
  AND `target`.`event_chance` = 100
  AND `target`.`action_type` = 80
  AND `target`.`action_param1` = 3719800
  AND `target`.`action_param2` = 0
  AND `target`.`target_type` = 1
  AND `target`.`comment` =
      'Milo''s Gyro - On Summoned - Run delayed waypoint start';

COMMIT;
