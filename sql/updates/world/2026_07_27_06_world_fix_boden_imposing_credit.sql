-- Quest 26315 "Imposing Confrontation":
-- item 58177 "Earthen Ring Proclamation" casts spell 79715 on Boden.
-- Replace the manual kill credit with the exact Build-18414 response spell
-- 79843 "Imposing Confrontation Credit". That spell applies the intended
-- knockback and grants objective credit 42731 to the selected player.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_boden_imposing_20260727`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_boden_imposing_20260727`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 42471
  AND `s`.`source_type` = 0
  AND `s`.`id` = 0
  AND `s`.`link` = 0
  AND `s`.`event_type` = 8
  AND `s`.`event_param1` = 79715
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 42731
  AND `s`.`target_type` = 7;

START TRANSACTION;

SET @boden_imposing_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_boden_imposing_20260727`
);

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 79843,
    `action_param2` = 2,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Boden the Imposing - Spell Hit by Earthen Ring Proclamation - Cast dedicated confrontation credit on player'
WHERE @boden_imposing_backup_ok = 1
  AND `entryorguid` = 42471
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 0
  AND `event_type` = 8
  AND `event_param1` = 79715
  AND `event_param2` = 0
  AND `action_type` = 33
  AND `action_param1` = 42731
  AND `target_type` = 7;

COMMIT;
