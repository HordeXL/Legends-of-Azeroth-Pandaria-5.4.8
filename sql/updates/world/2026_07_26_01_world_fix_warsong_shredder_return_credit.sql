-- Quest 13698 "Explosives Shredding":
-- use the dedicated Build-18414 shredder-return credit spell.
--
-- Preserve the vehicle, keg objective, return-distance event, aura/NPC-flag
-- cleanup, combat stop, and delayed despawn. Replace only the manual credit
-- issued after the shredder returns to Sentinel Luciel Starwhisper.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_warsong_shredder_return_20260726`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_warsong_shredder_return_20260726`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 33706
  AND `s`.`source_type` = 0
  AND `s`.`id` = 3
  AND `s`.`link` = 4
  AND `s`.`event_type` = 61
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 33709
  AND `s`.`target_type` = 21
  AND `s`.`target_param1` = 1;

START TRANSACTION;

SET @warsong_shredder_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_warsong_shredder_return_20260726`
);

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 63555,
    `action_param2` = 1,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Warsong Shredder - after return cast dedicated Shredder Return Kill Credit'
WHERE @warsong_shredder_backup_ok = 1
  AND `entryorguid` = 33706
  AND `source_type` = 0
  AND `id` = 3
  AND `link` = 4
  AND `event_type` = 61
  AND `action_type` = 33
  AND `action_param1` = 33709
  AND `target_type` = 21
  AND `target_param1` = 1;

COMMIT;
