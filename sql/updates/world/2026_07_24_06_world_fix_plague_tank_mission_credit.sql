-- Quest 11332 "Mission: Plague This!":
-- use the Build-18414 quest-credit spell instead of a manual SmartAI credit.
--
-- Spell 43404 is constrained by the active conditions table to creature 24290
-- (New Agamand Plague Tank Bunny). The quest objective requires five credits
-- for that same creature entry. Build-18414 spell 43419 contains exactly one
-- SPELL_EFFECT_KILL_CREDIT2 effect for creature 24290 and no other effects.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_plague_tank_mission_20260724`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_plague_tank_mission_20260724`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 24290
  AND `s`.`source_type` = 0
  AND `s`.`id` = 0
  AND `s`.`link` = 0
  AND `s`.`event_type` = 8
  AND `s`.`event_param1` = 43404
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 24290
  AND `s`.`target_type` = 7;

START TRANSACTION;

SET @plague_tank_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_plague_tank_mission_20260724`
);

UPDATE `smart_scripts`
SET `action_type` = 85,
    `action_param1` = 43419,
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
    `comment` = 'New Agamand Plague Tank Bunny - player casts mission credit spell'
WHERE @plague_tank_backup_ok = 1
  AND `entryorguid` = 24290
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 0
  AND `event_type` = 8
  AND `event_param1` = 43404
  AND `action_type` = 33
  AND `action_param1` = 24290
  AND `target_type` = 7;

COMMIT;
