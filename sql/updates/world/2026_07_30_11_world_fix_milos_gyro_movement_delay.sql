-- Delay Milo's Gyro movement for one second after it is summoned so the
-- player can board before the vehicle starts following its path.
--
-- Source:
--   ProjectSkyfire/SkyFire_548 commit
--   5f1ee7088f5659ce296b8c4a10217979f17cd406
--
-- This world already has a richer 23-point path with waypoint-driven dialogue.
-- Preserve that event and change only its immediate movement action into a
-- one-second timed action list.

CREATE TABLE IF NOT EXISTS
    `_backup_smart_scripts_milos_gyro_delay_20260730`
LIKE `smart_scripts`;

INSERT INTO `_backup_smart_scripts_milos_gyro_delay_20260730`
SELECT `smart`.*
FROM `smart_scripts` AS `smart`
WHERE `smart`.`entryorguid` = 37198
  AND `smart`.`source_type` = 0
  AND `smart`.`id` = 0
  AND `smart`.`link` = 0
  AND `smart`.`event_type` = 54
  AND `smart`.`event_chance` = 100
  AND `smart`.`action_type` = 53
  AND `smart`.`action_param1` = 1
  AND `smart`.`action_param2` = 37198
  AND `smart`.`target_type` = 1
  AND `smart`.`comment` =
      'Milo''s Gyro - On Summoned - Waypoint Start'
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_smart_scripts_milos_gyro_delay_20260730` AS `backup`
       WHERE `backup`.`entryorguid` = `smart`.`entryorguid`
         AND `backup`.`source_type` = `smart`.`source_type`
         AND `backup`.`id` = `smart`.`id`
         AND `backup`.`link` = `smart`.`link`);

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

SET @milos_gyro_delay_slot_ok :=
(
    SELECT COUNT(*) = 0
    FROM `smart_scripts`
    WHERE `entryorguid` = 3719800
      AND NOT
          (`source_type` = 9
           AND `id` = 0
           AND `link` = 0
           AND `event_type` = 0
           AND `event_param1` = 1000
           AND `event_param2` = 1000
           AND `action_type` = 53
           AND `action_param1` = 1
           AND `action_param2` = 37198
           AND `target_type` = 1)
);

UPDATE `smart_scripts`
SET
    `action_type` = 80,
    `action_param1` = 3719800,
    `action_param2` = 0,
    `comment` =
        'Milo''s Gyro - On Summoned - Run delayed waypoint start'
WHERE @milos_gyro_delay_backup_ok = 1
  AND @milos_gyro_delay_slot_ok = 1
  AND `entryorguid` = 37198
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 0
  AND `event_type` = 54
  AND `event_chance` = 100
  AND `action_type` = 53
  AND `action_param1` = 1
  AND `action_param2` = 37198
  AND `target_type` = 1
  AND `comment` =
      'Milo''s Gyro - On Summoned - Waypoint Start';

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`,
     `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`,
     `event_param5`, `action_type`, `action_param1`, `action_param2`,
     `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`,
     `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`,
     `comment`)
SELECT
    3719800, 9, 0, 0,
    0, 0, 100, 0,
    1000, 1000, 0, 0,
    0, 53, 1, 37198,
    0, 0, 0, 0,
    1, 0, 0, 0,
    0, 0, 0, 0, 0,
    'Milo''s Gyro - On Script - Start waypoint movement after 1 second'
FROM DUAL
WHERE @milos_gyro_delay_backup_ok = 1
  AND @milos_gyro_delay_slot_ok = 1
  AND EXISTS
      (SELECT 1
       FROM `smart_scripts`
       WHERE `entryorguid` = 37198
         AND `source_type` = 0
         AND `id` = 0
         AND `link` = 0
         AND `event_type` = 54
         AND `action_type` = 80
         AND `action_param1` = 3719800
         AND `action_param2` = 0
         AND `target_type` = 1)
  AND NOT EXISTS
      (SELECT 1
       FROM `smart_scripts`
       WHERE `entryorguid` = 3719800
         AND `source_type` = 9
         AND `id` = 0
         AND `link` = 0);

COMMIT;
