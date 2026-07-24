-- Quest 25499 "Agility Training: Run Like Hell!":
-- use the complete Build-18414 spell chain instead of duplicating its
-- summon and delayed quest-credit effects in SmartAI.
--
-- The quest accept event retains the player as the timed action list's last
-- invoker.  SMART_ACTION_INVOKER_CAST therefore makes that player cast 75397
-- on self.  Spell 75397 summons Blazing Trainer (40434), applies its
-- 60-second periodic aura, and triggers spell 75398, which grants credit
-- for entry 40440 to the same player.
--
-- The existing 55-second NPC-flag pause is preserved by moving that delay
-- from the removed manual-credit row to the following NPC-flag restore row.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_instructor_mylva_20260724`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_instructor_mylva_20260724`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 3941300
  AND `s`.`source_type` = 9
  AND `s`.`id` BETWEEN 0 AND 3;

START TRANSACTION;

SET @mylva_backup_ok :=
(
    SELECT COUNT(*) = 4
    FROM `_backup_smart_scripts_instructor_mylva_20260724`
);

UPDATE `smart_scripts`
SET `action_type` = 85,
    `action_param1` = 75397,
    `action_param2` = 1,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `target_type` = 7,
    `target_param1` = 0,
    `target_param2` = 0,
    `target_param3` = 0,
    `target_x` = 0,
    `target_y` = 0,
    `target_z` = 0,
    `target_o` = 0,
    `comment` = 'Instructor Mylva - player casts complete training spell chain'
WHERE @mylva_backup_ok = 1
  AND `entryorguid` = 3941300
  AND `source_type` = 9
  AND `id` = 0
  AND `event_type` = 0
  AND `action_type` = 12
  AND `action_param1` = 40434
  AND `target_type` = 1;

DELETE FROM `smart_scripts`
WHERE @mylva_backup_ok = 1
  AND `entryorguid` = 3941300
  AND `source_type` = 9
  AND `id` = 2
  AND `event_type` = 0
  AND `event_param1` = 55000
  AND `event_param2` = 55000
  AND `action_type` = 33
  AND `action_param1` = 40440
  AND `target_type` = 7;

UPDATE `smart_scripts`
SET `event_param1` = 55000,
    `event_param2` = 55000
WHERE @mylva_backup_ok = 1
  AND `entryorguid` = 3941300
  AND `source_type` = 9
  AND `id` = 3
  AND `event_type` = 0
  AND `event_param1` = 0
  AND `event_param2` = 0
  AND `action_type` = 82
  AND `action_param1` = 2
  AND `target_type` = 1;

COMMIT;
