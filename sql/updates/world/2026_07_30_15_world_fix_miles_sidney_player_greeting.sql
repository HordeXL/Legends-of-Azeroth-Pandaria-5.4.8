-- Miles Sidney (28347): make his OOC LOS greeting originate from Miles and
-- trigger only when the unit entering line of sight is a player.
--
-- The original action targets SMART_TARGET_ACTION_INVOKER. A nearby friendly
-- NPC, Wright Williams (28355), can therefore trigger the event and is then
-- incorrectly ordered to say Miles' creature_text group 5. Wright has only
-- groups 0-3, which produces:
--   CreatureTextMgr: Could not find TextGroup 5 for Creature(Wright Williams)
--
-- Do not invent a Wright group 5. Miles already owns the five authentic
-- group-5 vendor greetings. Target Miles himself and constrain the invoker to
-- TYPEID_PLAYER.

CREATE TABLE IF NOT EXISTS
    `_backup_smart_scripts_miles_sidney_greeting_20260730`
LIKE `smart_scripts`;

INSERT INTO `_backup_smart_scripts_miles_sidney_greeting_20260730`
SELECT `smart`.*
FROM `smart_scripts` AS `smart`
WHERE `smart`.`entryorguid` = 28347
  AND `smart`.`source_type` = 0
  AND `smart`.`id` = 1
  AND `smart`.`link` = 0
  AND `smart`.`event_type` = 10
  AND `smart`.`event_param1` = 1
  AND `smart`.`event_param2` = 20
  AND `smart`.`action_type` = 1
  AND `smart`.`action_param1` = 5
  AND `smart`.`target_type` = 7
ON DUPLICATE KEY UPDATE
    `entryorguid` = VALUES(`entryorguid`);

CREATE TABLE IF NOT EXISTS
    `_backup_conditions_miles_sidney_greeting_20260730`
LIKE `conditions`;

-- This is intentionally guarded by the still-unmodified SmartAI row. It
-- prevents a repeated apply from backing up the condition introduced below.
INSERT INTO `_backup_conditions_miles_sidney_greeting_20260730`
SELECT `condition`.*
FROM `conditions` AS `condition`
WHERE `condition`.`SourceTypeOrReferenceId` = 22
  AND `condition`.`SourceGroup` = 2
  AND `condition`.`SourceEntry` = 28347
  AND `condition`.`SourceId` = 0
  AND EXISTS
  (
      SELECT 1
      FROM `smart_scripts` AS `smart`
      WHERE `smart`.`entryorguid` = 28347
        AND `smart`.`source_type` = 0
        AND `smart`.`id` = 1
        AND `smart`.`event_type` = 10
        AND `smart`.`action_type` = 1
        AND `smart`.`action_param1` = 5
        AND `smart`.`target_type` = 7
  )
ON DUPLICATE KEY UPDATE
    `SourceTypeOrReferenceId` = VALUES(`SourceTypeOrReferenceId`);

START TRANSACTION;

SET @miles_sidney_greeting_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`entryorguid` = 28347
               AND `source_type` = 0
               AND `id` = 1
               AND `link` = 0
               AND `event_type` = 10
               AND `event_param1` = 1
               AND `event_param2` = 20
               AND `action_type` = 1
               AND `action_param1` = 5
               AND `target_type` = 7) = 1
    FROM `_backup_smart_scripts_miles_sidney_greeting_20260730`
);

UPDATE `smart_scripts`
SET `target_type` = 1
WHERE @miles_sidney_greeting_backup_ok = 1
  AND `entryorguid` = 28347
  AND `source_type` = 0
  AND `id` = 1
  AND `link` = 0
  AND `event_type` = 10
  AND `event_param1` = 1
  AND `event_param2` = 20
  AND `action_type` = 1
  AND `action_param1` = 5
  AND `target_type` = 7;

INSERT INTO `conditions`
(
    `SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
    `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
    `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
    `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`
)
SELECT
    22, 2, 28347, 0, 0, 31, 0, 4, 0, 0, 0, 0, 0, '',
    'Miles Sidney SmartAI event 1 - invoker must be a player'
FROM DUAL
WHERE @miles_sidney_greeting_backup_ok = 1
  AND EXISTS
  (
      SELECT 1
      FROM `smart_scripts`
      WHERE `entryorguid` = 28347
        AND `source_type` = 0
        AND `id` = 1
        AND `event_type` = 10
        AND `action_type` = 1
        AND `action_param1` = 5
        AND `target_type` = 1
  )
  AND NOT EXISTS
  (
      SELECT 1
      FROM `conditions`
      WHERE `SourceTypeOrReferenceId` = 22
        AND `SourceGroup` = 2
        AND `SourceEntry` = 28347
        AND `SourceId` = 0
        AND `ElseGroup` = 0
        AND `ConditionTypeOrReference` = 31
        AND `ConditionTarget` = 0
        AND `ConditionValue1` = 4
        AND `ConditionValue2` = 0
        AND `ConditionValue3` = 0
  );

COMMIT;
