-- Quest 14129 "Runaway Shredder!":
-- use the dedicated Build-18414 personal credit spell.
--
-- The existing SmartAI stores the spell-clicking player in target list 1,
-- waits two seconds, and makes the nearby pilot cast spell 66787 before this
-- row runs. Spell 66788 ("Kill Credit") contains the personal kill-credit
-- effect for Runaway Shredder 35111 and an associated passenger script
-- effect. Casting it on the already stored player preserves ownership and
-- the complete client spell behavior.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_runaway_shredder_20260724`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_runaway_shredder_20260724`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 35111
  AND `s`.`source_type` = 0
  AND `s`.`id` = 8
  AND `s`.`link` = 9
  AND `s`.`event_type` = 61
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 35111
  AND `s`.`target_type` = 12
  AND `s`.`target_param1` = 1;

START TRANSACTION;

SET @runaway_shredder_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_runaway_shredder_20260724`
);

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 66788,
    `action_param2` = 1,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `target_type` = 12,
    `target_param1` = 1,
    `target_param2` = 0,
    `target_param3` = 0,
    `target_x` = 0,
    `target_y` = 0,
    `target_z` = 0,
    `target_o` = 0,
    `comment` = 'Runaway Shredder - cast complete personal credit spell on stored player'
WHERE @runaway_shredder_backup_ok = 1
  AND `entryorguid` = 35111
  AND `source_type` = 0
  AND `id` = 8
  AND `link` = 9
  AND `event_type` = 61
  AND `action_type` = 33
  AND `action_param1` = 35111
  AND `target_type` = 12
  AND `target_param1` = 1;

COMMIT;
