-- Quest 14196 "Firestarter":
-- use the dedicated Build-18414 Raging Vortex credit spell.
--
-- The player uses Vortex Gem spell 67410 and owns the summoned Wispy
-- Vortex. After its complete five-stage charge chain, spell 67431 grants
-- credit 35392 to the Vortex's master. Preserve all charge auras/effects.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_wispy_vortex_credit_20260727`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_wispy_vortex_credit_20260727`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 35386
  AND `s`.`source_type` = 0
  AND `s`.`id` = 16
  AND `s`.`link` = 17
  AND `s`.`event_type` = 61
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 35392
  AND `s`.`target_type` = 12
  AND `s`.`target_param1` = 1;

START TRANSACTION;

SET @wispy_vortex_credit_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_wispy_vortex_credit_20260727`
);

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 67431,
    `action_param2` = 2,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `target_type` = 1,
    `target_param1` = 0,
    `target_param2` = 0,
    `target_param3` = 0,
    `target_param4` = 0,
    `target_x` = 0,
    `target_y` = 0,
    `target_z` = 0,
    `target_o` = 0,
    `comment` = 'Wispy Vortex - after final charge cast dedicated Raging Vortex credit on owner'
WHERE @wispy_vortex_credit_backup_ok = 1
  AND `entryorguid` = 35386
  AND `source_type` = 0
  AND `id` = 16
  AND `link` = 17
  AND `event_type` = 61
  AND `action_type` = 33
  AND `action_param1` = 35392
  AND `target_type` = 12
  AND `target_param1` = 1;

COMMIT;
