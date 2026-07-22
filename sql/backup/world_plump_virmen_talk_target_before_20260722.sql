-- Exact rollback for
-- 2026_07_22_07_world_fix_plump_virmen_talk_target.sql.

START TRANSACTION;

SET @plump_virmen_backup_ok :=
(
    SELECT COUNT(*) = 12
    FROM `_backup_smart_scripts_plump_virmen_talk_20260722`
);

UPDATE `smart_scripts` AS `s`
JOIN `_backup_smart_scripts_plump_virmen_talk_20260722` AS `backup`
  ON `backup`.`entryorguid` = `s`.`entryorguid`
 AND `backup`.`source_type` = `s`.`source_type`
 AND `backup`.`id` = `s`.`id`
 AND `backup`.`link` = `s`.`link`
SET `s`.`target_type` = `backup`.`target_type`,
    `s`.`target_param1` = `backup`.`target_param1`,
    `s`.`target_param2` = `backup`.`target_param2`,
    `s`.`target_param3` = `backup`.`target_param3`,
    `s`.`target_x` = `backup`.`target_x`,
    `s`.`target_y` = `backup`.`target_y`,
    `s`.`target_z` = `backup`.`target_z`,
    `s`.`target_o` = `backup`.`target_o`
WHERE @plump_virmen_backup_ok = 1
  AND `s`.`entryorguid` IN
      (55483, -562577, -562655, -562663, -562695, -562724,
       -563630, -563644, -563645, -563646, -563647, -563648)
  AND `s`.`event_type` = 4
  AND `s`.`action_type` = 1
  AND `s`.`action_param1` = 0
  AND `s`.`comment` = 'Plump Virmen - On Aggro - Say Text Line 0';

COMMIT;
