-- Quest 13805 "Pierce Their Heart!":
-- use the dedicated Build-18414 Forest Heart credit spell.
--
-- Quest item 45683 (Tainted Blood of the Kaldorei) casts spell 63797
-- ("Throw Blood"). Its active condition targets creature 33847, matching the
-- quest objective. Build-18414 spell 63810 ("Forest Heart Kill Credit")
-- contains exactly one SPELL_EFFECT_KILL_CREDIT2 effect for creature 33847.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_forest_heart_20260724`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_forest_heart_20260724`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 33847
  AND `s`.`source_type` = 0
  AND `s`.`id` = 0
  AND `s`.`link` = 0
  AND `s`.`event_type` = 8
  AND `s`.`event_param1` = 63797
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 33847
  AND `s`.`target_type` = 7;

START TRANSACTION;

SET @forest_heart_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_forest_heart_20260724`
);

UPDATE `smart_scripts`
SET `action_type` = 85,
    `action_param1` = 63810,
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
    `comment` = 'Forest Heart Bunny (Horde) - player casts Forest Heart credit spell'
WHERE @forest_heart_backup_ok = 1
  AND `entryorguid` = 33847
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 0
  AND `event_type` = 8
  AND `event_param1` = 63797
  AND `action_type` = 33
  AND `action_param1` = 33847
  AND `target_type` = 7;

COMMIT;
