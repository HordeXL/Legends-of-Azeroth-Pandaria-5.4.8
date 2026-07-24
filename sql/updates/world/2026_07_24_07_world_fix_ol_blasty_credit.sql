-- Quest 26647 "Ol' Blasty":
-- use the Build-18414 personal credit spell instead of a manual SmartAI credit.
--
-- Cannonball spell 81507 is constrained by the active conditions table to
-- creature 43560 (Smilin' Timmy Sticks). The quest objective requires five
-- hits on that creature. Build-18414 spell 81524 contains exactly one
-- SPELL_EFFECT_KILL_CREDIT effect for creature 43560 and no other effects.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_ol_blasty_20260724`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_ol_blasty_20260724`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 43560
  AND `s`.`source_type` = 0
  AND `s`.`id` = 0
  AND `s`.`link` = 0
  AND `s`.`event_type` = 8
  AND `s`.`event_param1` = 81507
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 43560
  AND `s`.`target_type` = 7;

START TRANSACTION;

SET @ol_blasty_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_ol_blasty_20260724`
);

UPDATE `smart_scripts`
SET `action_type` = 85,
    `action_param1` = 81524,
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
    `comment` = 'Smilin'' Timmy Sticks - player casts Ol'' Blasty credit spell'
WHERE @ol_blasty_backup_ok = 1
  AND `entryorguid` = 43560
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 0
  AND `event_type` = 8
  AND `event_param1` = 81507
  AND `action_type` = 33
  AND `action_param1` = 43560
  AND `target_type` = 7;

COMMIT;
