-- Quest 29966 "Burning Down the House":
-- use the complete Build-18414 Alliance Camp credit spell.
--
-- Quest item 76336 (Nazgrim's Grog) casts spell 106243. Its active spell
-- condition targets creature 56509 (Alliance Camp), which is also the quest's
-- single objective credit. Build-18414 spell 106245 is explicitly named
-- "Alliance Camp Burning Credit"; it grants credit 56509 and triggers the
-- associated quest-invisibility spell 106244.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_alliance_camp_20260724`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_alliance_camp_20260724`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 56509
  AND `s`.`source_type` = 0
  AND `s`.`id` = 0
  AND `s`.`link` = 0
  AND `s`.`event_type` = 8
  AND `s`.`event_param1` = 106243
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 56509
  AND `s`.`target_type` = 7;

START TRANSACTION;

SET @alliance_camp_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_alliance_camp_20260724`
);

UPDATE `smart_scripts`
SET `action_type` = 85,
    `action_param1` = 106245,
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
    `comment` = 'Alliance Camp - player casts complete burning credit spell'
WHERE @alliance_camp_backup_ok = 1
  AND `entryorguid` = 56509
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 0
  AND `event_type` = 8
  AND `event_param1` = 106243
  AND `action_type` = 33
  AND `action_param1` = 56509
  AND `target_type` = 7;

COMMIT;
