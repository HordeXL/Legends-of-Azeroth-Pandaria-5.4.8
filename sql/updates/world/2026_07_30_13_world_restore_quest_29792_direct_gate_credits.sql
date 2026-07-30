-- Quest 29792 "Bidden to Greatness": restore the two directly tested player
-- credits for the Mandori Village and Pei-Wu Forest gate objectives.
--
-- Regression source:
--   2026_07_27_08_world_fix_one_hundred_source_backed_smartai_spells.sql
-- replaced the working SMART_ACTION_CALL_KILLEDMONSTER actions with spells
-- 115442/115443 targeted at the acting NPC itself. The complete gate scene
-- and both gate animations still run, but the player receives neither
-- objective 59946 nor objective 59947.
--
-- The exact pre-regression rows are retained in
-- _backup_smart_scripts_one_hundred_spells_20260727. Restore only these two
-- rows; do not change any gate, phase, waypoint, dialogue or other SmartAI.

CREATE TABLE IF NOT EXISTS
    `_backup_smart_scripts_quest_29792_credit_spells_20260730`
LIKE `smart_scripts`;

INSERT INTO `_backup_smart_scripts_quest_29792_credit_spells_20260730`
SELECT `smart`.*
FROM `smart_scripts` AS `smart`
WHERE
      (`smart`.`entryorguid` = 5998600
       AND `smart`.`source_type` = 9
       AND `smart`.`id` = 1
       AND `smart`.`link` = 0
       AND `smart`.`event_type` = 0
       AND `smart`.`action_type` = 11
       AND `smart`.`action_param1` = 115442
       AND `smart`.`action_param2` = 2
       AND `smart`.`target_type` = 1
       AND `smart`.`comment` =
           'Aysa Cloudsinger - On Script - Quest Credit - Cast source-backed spell 115442')
   OR (`smart`.`entryorguid` = 59986
       AND `smart`.`source_type` = 0
       AND `smart`.`id` = 11
       AND `smart`.`link` = 0
       AND `smart`.`event_type` = 61
       AND `smart`.`action_type` = 11
       AND `smart`.`action_param1` = 115443
       AND `smart`.`action_param2` = 2
       AND `smart`.`target_type` = 1
       AND `smart`.`comment` =
           'Aysa Cloudsinger - Linked To Id 10 - Quest Credit - Cast source-backed spell 115443')
ON DUPLICATE KEY UPDATE
    `entryorguid` = VALUES(`entryorguid`);

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
               AND `action_param2` = 2
               AND `target_type` = 1) = 1
       AND SUM(`entryorguid` = 59986
               AND `source_type` = 0
               AND `id` = 11
               AND `event_type` = 61
               AND `action_type` = 11
               AND `action_param1` = 115443
               AND `action_param2` = 2
               AND `target_type` = 1) = 1
    FROM `_backup_smart_scripts_quest_29792_credit_spells_20260730`
);

SET @quest_29792_original_backup_ok :=
(
    SELECT COUNT(*) = 2
       AND SUM(`entryorguid` = 5998600
               AND `source_type` = 9
               AND `id` = 1
               AND `event_type` = 0
               AND `action_type` = 33
               AND `action_param1` = 59946
               AND `target_type` = 12
               AND `target_param1` = 1) = 1
       AND SUM(`entryorguid` = 59986
               AND `source_type` = 0
               AND `id` = 11
               AND `event_type` = 61
               AND `action_type` = 33
               AND `action_param1` = 59947
               AND `target_type` = 12
               AND `target_param1` = 1) = 1
    FROM `_backup_smart_scripts_one_hundred_spells_20260727`
    WHERE (`entryorguid` = 5998600
           AND `source_type` = 9
           AND `id` = 1
           AND `event_type` = 0)
       OR (`entryorguid` = 59986
           AND `source_type` = 0
           AND `id` = 11
           AND `event_type` = 61)
);

UPDATE `smart_scripts` AS `active`
INNER JOIN `_backup_smart_scripts_one_hundred_spells_20260727` AS `original`
    ON `original`.`entryorguid` = `active`.`entryorguid`
   AND `original`.`source_type` = `active`.`source_type`
   AND `original`.`id` = `active`.`id`
   AND `original`.`event_type` = `active`.`event_type`
SET
    `active`.`action_type` = `original`.`action_type`,
    `active`.`action_param1` = `original`.`action_param1`,
    `active`.`action_param2` = `original`.`action_param2`,
    `active`.`action_param3` = `original`.`action_param3`,
    `active`.`action_param4` = `original`.`action_param4`,
    `active`.`action_param5` = `original`.`action_param5`,
    `active`.`action_param6` = `original`.`action_param6`,
    `active`.`target_type` = `original`.`target_type`,
    `active`.`target_param1` = `original`.`target_param1`,
    `active`.`target_param2` = `original`.`target_param2`,
    `active`.`target_param3` = `original`.`target_param3`,
    `active`.`target_x` = `original`.`target_x`,
    `active`.`target_y` = `original`.`target_y`,
    `active`.`target_z` = `original`.`target_z`,
    `active`.`target_o` = `original`.`target_o`,
    `active`.`comment` = `original`.`comment`
WHERE @quest_29792_spell_backup_ok = 1
  AND @quest_29792_original_backup_ok = 1
  AND
      ((`active`.`entryorguid` = 5998600
        AND `active`.`source_type` = 9
        AND `active`.`id` = 1
        AND `active`.`event_type` = 0
        AND `active`.`action_type` = 11
        AND `active`.`action_param1` = 115442
        AND `active`.`target_type` = 1)
       OR
       (`active`.`entryorguid` = 59986
        AND `active`.`source_type` = 0
        AND `active`.`id` = 11
        AND `active`.`event_type` = 61
        AND `active`.`action_type` = 11
        AND `active`.`action_param1` = 115443
        AND `active`.`target_type` = 1));

COMMIT;
