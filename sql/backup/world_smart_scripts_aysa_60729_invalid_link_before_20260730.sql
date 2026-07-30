-- Exact rollback for
-- 2026_07_30_14_world_fix_aysa_60729_invalid_link.sql.
--
-- Restore only Aysa Cloudsinger (60729) SmartAI row 18 captured immediately
-- before the invalid-link repair.

START TRANSACTION;

SET @aysa_60729_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`entryorguid` = 60729
               AND `source_type` = 0
               AND `id` = 18
               AND `link` = 19
               AND `event_type` = 61
               AND `action_type` = 97
               AND `target_type` = 1
               AND ABS(`target_x` - 239.453) < 0.001
               AND ABS(`target_y` - 3942.2) < 0.001
               AND ABS(`target_z` - 62.5987) < 0.001) = 1
    FROM `_backup_smart_scripts_aysa_60729_invalid_link_20260730`
);

UPDATE `smart_scripts` AS `active`
INNER JOIN `_backup_smart_scripts_aysa_60729_invalid_link_20260730` AS `backup`
    ON `backup`.`entryorguid` = `active`.`entryorguid`
   AND `backup`.`source_type` = `active`.`source_type`
   AND `backup`.`id` = `active`.`id`
   AND `backup`.`event_type` = `active`.`event_type`
SET `active`.`link` = `backup`.`link`
WHERE @aysa_60729_backup_ok = 1
  AND `active`.`entryorguid` = 60729
  AND `active`.`source_type` = 0
  AND `active`.`id` = 18
  AND `active`.`link` = 0
  AND `active`.`event_type` = 61
  AND `active`.`action_type` = 97
  AND `active`.`target_type` = 1
  AND ABS(`active`.`target_x` - 239.453) < 0.001
  AND ABS(`active`.`target_y` - 3942.2) < 0.001
  AND ABS(`active`.`target_z` - 62.5987) < 0.001;

COMMIT;
