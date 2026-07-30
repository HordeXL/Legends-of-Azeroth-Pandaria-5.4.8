-- Exact rollback for
-- 2026_07_30_13_world_restore_quest_29792_direct_gate_credits.sql.
--
-- Restore only the two source-backed spell rows captured immediately before
-- the targeted regression repair.

START TRANSACTION;

SET @quest_29792_spell_backup_ok :=
(
    SELECT COUNT(*) = 2
       AND SUM(`entryorguid` = 5998600
               AND `source_type` = 9
               AND `id` = 1
               AND `event_type` = 0
               AND `action_type` = 11
               AND `action_param1` = 115442
               AND `target_type` = 1) = 1
       AND SUM(`entryorguid` = 59986
               AND `source_type` = 0
               AND `id` = 11
               AND `event_type` = 61
               AND `action_type` = 11
               AND `action_param1` = 115443
               AND `target_type` = 1) = 1
    FROM `_backup_smart_scripts_quest_29792_credit_spells_20260730`
);

UPDATE `smart_scripts` AS `active`
INNER JOIN `_backup_smart_scripts_quest_29792_credit_spells_20260730` AS `backup`
    ON `backup`.`entryorguid` = `active`.`entryorguid`
   AND `backup`.`source_type` = `active`.`source_type`
   AND `backup`.`id` = `active`.`id`
   AND `backup`.`event_type` = `active`.`event_type`
SET
    `active`.`action_type` = `backup`.`action_type`,
    `active`.`action_param1` = `backup`.`action_param1`,
    `active`.`action_param2` = `backup`.`action_param2`,
    `active`.`action_param3` = `backup`.`action_param3`,
    `active`.`action_param4` = `backup`.`action_param4`,
    `active`.`action_param5` = `backup`.`action_param5`,
    `active`.`action_param6` = `backup`.`action_param6`,
    `active`.`target_type` = `backup`.`target_type`,
    `active`.`target_param1` = `backup`.`target_param1`,
    `active`.`target_param2` = `backup`.`target_param2`,
    `active`.`target_param3` = `backup`.`target_param3`,
    `active`.`target_x` = `backup`.`target_x`,
    `active`.`target_y` = `backup`.`target_y`,
    `active`.`target_z` = `backup`.`target_z`,
    `active`.`target_o` = `backup`.`target_o`,
    `active`.`comment` = `backup`.`comment`
WHERE @quest_29792_spell_backup_ok = 1
  AND
      ((`active`.`entryorguid` = 5998600
        AND `active`.`source_type` = 9
        AND `active`.`id` = 1
        AND `active`.`event_type` = 0
        AND `active`.`action_type` = 33
        AND `active`.`action_param1` = 59946
        AND `active`.`target_type` = 12
        AND `active`.`target_param1` = 1)
       OR
       (`active`.`entryorguid` = 59986
        AND `active`.`source_type` = 0
        AND `active`.`id` = 11
        AND `active`.`event_type` = 61
        AND `active`.`action_type` = 33
        AND `active`.`action_param1` = 59947
        AND `active`.`target_type` = 12
        AND `active`.`target_param1` = 1));

COMMIT;
