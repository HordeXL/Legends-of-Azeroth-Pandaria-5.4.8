-- Exact rollback for
-- 2026_07_23_00_world_restore_waypoint_script_broadcast_texts_part2.sql.

START TRANSACTION;

SET @waypoint_talk_part2_backup_ok :=
(
    SELECT COUNT(*) = 5
       AND SUM(`guid` = 2   AND `id` = 24)  = 1
       AND SUM(`guid` = 300 AND `id` = 24)  = 1
       AND SUM(`guid` = 99  AND `id` = 156) = 1
       AND SUM(`guid` = 140 AND `id` = 212) = 1
       AND SUM(`guid` = 141 AND `id` = 213) = 1
    FROM `_backup_waypoint_scripts_talk_part2_20260723`
);

UPDATE `waypoint_scripts` AS `ws`
JOIN `_backup_waypoint_scripts_talk_part2_20260723` AS `backup`
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
WHERE @waypoint_talk_part2_backup_ok = 1
  AND `ws`.`guid` IN (2, 99, 140, 141, 300)
  AND `ws`.`id` IN (24, 156, 212, 213);

COMMIT;
