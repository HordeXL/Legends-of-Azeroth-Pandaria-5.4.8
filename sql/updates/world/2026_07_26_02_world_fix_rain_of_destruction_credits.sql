-- Quest 13798 "Rain of Destruction":
-- use the two dedicated Build-18414 personal-credit spells.
--
-- The projectile bunny stores its summoning player in target list 1.
-- Preserve the complete marker/data/explosion/death chain and replace only
-- the two manual credits issued for an ancient or an attacking elf.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_rain_of_destruction_20260726`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_rain_of_destruction_20260726`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 33965
  AND `s`.`source_type` = 0
  AND
  (
      (
          `s`.`id` = 8
          AND `s`.`link` = 10
          AND `s`.`event_type` = 38
          AND `s`.`event_param1` = 3
          AND `s`.`event_param2` = 0
          AND `s`.`action_type` = 33
          AND `s`.`action_param1` = 33969
      )
      OR
      (
          `s`.`id` = 9
          AND `s`.`link` = 10
          AND `s`.`event_type` = 38
          AND `s`.`event_param1` = 4
          AND `s`.`event_param2` = 0
          AND `s`.`action_type` = 33
          AND `s`.`action_param1` = 33965
      )
  )
  AND `s`.`target_type` = 12
  AND `s`.`target_param1` = 1;

START TRANSACTION;

SET @rain_of_destruction_backup_ok :=
(
    SELECT COUNT(*) = 2
    FROM `_backup_smart_scripts_rain_of_destruction_20260726`
);

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 64106,
    `action_param2` = 1,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Felfire Projectile Bunny - on ancient result cast Ancient Kill Credit on stored player'
WHERE @rain_of_destruction_backup_ok = 1
  AND `entryorguid` = 33965
  AND `source_type` = 0
  AND `id` = 8
  AND `link` = 10
  AND `event_type` = 38
  AND `event_param1` = 3
  AND `event_param2` = 0
  AND `action_type` = 33
  AND `action_param1` = 33969
  AND `target_type` = 12
  AND `target_param1` = 1;

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 64096,
    `action_param2` = 1,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Felfire Projectile Bunny - on elf result cast Kill Credit on stored player'
WHERE @rain_of_destruction_backup_ok = 1
  AND `entryorguid` = 33965
  AND `source_type` = 0
  AND `id` = 9
  AND `link` = 10
  AND `event_type` = 38
  AND `event_param1` = 4
  AND `event_param2` = 0
  AND `action_type` = 33
  AND `action_param1` = 33965
  AND `target_type` = 12
  AND `target_param1` = 1;

COMMIT;
