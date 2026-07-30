-- Exact rollback for
-- 2026_07_30_15_world_fix_miles_sidney_player_greeting.sql.

START TRANSACTION;

SET @miles_sidney_greeting_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`entryorguid` = 28347
               AND `source_type` = 0
               AND `id` = 1
               AND `event_type` = 10
               AND `action_type` = 1
               AND `action_param1` = 5
               AND `target_type` = 7) = 1
    FROM `_backup_smart_scripts_miles_sidney_greeting_20260730`
);

-- Remove only the player condition added by the update. If that exact row
-- already existed before the update, its backup keeps it intact.
DELETE `active`
FROM `conditions` AS `active`
WHERE @miles_sidney_greeting_backup_ok = 1
  AND `active`.`SourceTypeOrReferenceId` = 22
  AND `active`.`SourceGroup` = 2
  AND `active`.`SourceEntry` = 28347
  AND `active`.`SourceId` = 0
  AND `active`.`ElseGroup` = 0
  AND `active`.`ConditionTypeOrReference` = 31
  AND `active`.`ConditionTarget` = 0
  AND `active`.`ConditionValue1` = 4
  AND `active`.`ConditionValue2` = 0
  AND `active`.`ConditionValue3` = 0
  AND NOT EXISTS
  (
      SELECT 1
      FROM `_backup_conditions_miles_sidney_greeting_20260730` AS `backup`
      WHERE `backup`.`SourceTypeOrReferenceId` =
                `active`.`SourceTypeOrReferenceId`
        AND `backup`.`SourceGroup` = `active`.`SourceGroup`
        AND `backup`.`SourceEntry` = `active`.`SourceEntry`
        AND `backup`.`SourceId` = `active`.`SourceId`
        AND `backup`.`ElseGroup` = `active`.`ElseGroup`
        AND `backup`.`ConditionTypeOrReference` =
                `active`.`ConditionTypeOrReference`
        AND `backup`.`ConditionTarget` = `active`.`ConditionTarget`
        AND `backup`.`ConditionValue1` = `active`.`ConditionValue1`
        AND `backup`.`ConditionValue2` = `active`.`ConditionValue2`
        AND `backup`.`ConditionValue3` = `active`.`ConditionValue3`
  );

UPDATE `smart_scripts` AS `active`
INNER JOIN `_backup_smart_scripts_miles_sidney_greeting_20260730` AS `backup`
    ON `backup`.`entryorguid` = `active`.`entryorguid`
   AND `backup`.`source_type` = `active`.`source_type`
   AND `backup`.`id` = `active`.`id`
   AND `backup`.`event_type` = `active`.`event_type`
SET `active`.`target_type` = `backup`.`target_type`
WHERE @miles_sidney_greeting_backup_ok = 1
  AND `active`.`entryorguid` = 28347
  AND `active`.`source_type` = 0
  AND `active`.`id` = 1
  AND `active`.`link` = 0
  AND `active`.`event_type` = 10
  AND `active`.`event_param1` = 1
  AND `active`.`event_param2` = 20
  AND `active`.`action_type` = 1
  AND `active`.`action_param1` = 5
  AND `active`.`target_type` = 1;

COMMIT;
