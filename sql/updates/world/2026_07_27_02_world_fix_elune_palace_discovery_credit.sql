-- Quest 14195 "All Becoming Clearer":
-- use the dedicated Build-18414 Elune Palace discovery credit spell.
--
-- Preserve the existing ten-yard player selection and one-second discovery
-- check. Spell 67405 has only one effect: personal credit for creature 35382
-- on the explicitly selected unit.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_elune_palace_credit_20260727`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_elune_palace_credit_20260727`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 35382
  AND `s`.`source_type` = 0
  AND `s`.`id` = 0
  AND `s`.`link` = 0
  AND `s`.`event_type` = 1
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 35382
  AND `s`.`target_type` = 17
  AND `s`.`target_param1` = 0
  AND `s`.`target_param2` = 10;

START TRANSACTION;

SET @elune_palace_credit_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_elune_palace_credit_20260727`
);

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 67405,
    `action_param2` = 2,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Elune Palace Bunny - within 10 yards cast dedicated discovery credit on players'
WHERE @elune_palace_credit_backup_ok = 1
  AND `entryorguid` = 35382
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 0
  AND `event_type` = 1
  AND `action_type` = 33
  AND `action_param1` = 35382
  AND `target_type` = 17
  AND `target_param1` = 0
  AND `target_param2` = 10;

COMMIT;
