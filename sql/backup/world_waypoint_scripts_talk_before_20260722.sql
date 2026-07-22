-- Exact rollback for
-- 2026_07_22_06_world_restore_waypoint_script_broadcast_texts.sql.

START TRANSACTION;

SET @waypoint_talk_backup_ok :=
(
    SELECT COUNT(*) = 26
    FROM `_backup_waypoint_scripts_talk_20260722`
);

UPDATE `waypoint_scripts` AS `ws`
JOIN `_backup_waypoint_scripts_talk_20260722` AS `backup`
  ON `backup`.`guid` = `ws`.`guid`
SET `ws`.`id` = `backup`.`id`,
    `ws`.`delay` = `backup`.`delay`,
    `ws`.`command` = `backup`.`command`,
    `ws`.`datalong` = `backup`.`datalong`,
    `ws`.`datalong2` = `backup`.`datalong2`,
    `ws`.`dataint` = `backup`.`dataint`,
    `ws`.`x` = `backup`.`x`,
    `ws`.`y` = `backup`.`y`,
    `ws`.`z` = `backup`.`z`,
    `ws`.`o` = `backup`.`o`,
    `ws`.`Comment` = `backup`.`Comment`
WHERE @waypoint_talk_backup_ok = 1
  AND `ws`.`id` IN
      (336, 337, 351, 352, 354, 426, 427, 428, 446,
       460, 491, 499, 500, 501, 537, 538, 539, 540);

COMMIT;
