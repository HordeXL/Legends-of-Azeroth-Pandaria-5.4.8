-- The Valiant's Challenge (all ten faction variants):
-- use the dedicated Build-18414 Mounted Melee Victory credit spell.
--
-- The Argent Champion signals Squire Danny after surrender. Danny has
-- retained the player who started the duel in stored target list 1.
-- SMART_ACTION_CROSS_CAST therefore makes that exact stored player cast
-- spell 63516 on themselves; its caster-targeted kill-credit effect grants
-- credit 33708 to the correct challenger.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_squire_danny_20260726`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_squire_danny_20260726`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 33518
  AND `s`.`source_type` = 0
  AND `s`.`id` = 3
  AND `s`.`link` = 0
  AND `s`.`event_type` = 38
  AND `s`.`event_param1` = 0
  AND `s`.`event_param2` = 1
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 33708
  AND `s`.`target_type` = 12
  AND `s`.`target_param1` = 1;

START TRANSACTION;

SET @squire_danny_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_squire_danny_20260726`
);

UPDATE `smart_scripts`
SET `action_type` = 86,
    `action_param1` = 63516,
    `action_param2` = 1,
    `action_param3` = 12,
    `action_param4` = 1,
    `action_param5` = 0,
    `action_param6` = 0,
    `target_type` = 12,
    `target_param1` = 1,
    `target_param2` = 0,
    `target_param3` = 0,
    `comment` = 'Squire Danny - on champion surrender make stored challenger cast Mounted Melee Victory credit'
WHERE @squire_danny_backup_ok = 1
  AND `entryorguid` = 33518
  AND `source_type` = 0
  AND `id` = 3
  AND `link` = 0
  AND `event_type` = 38
  AND `event_param1` = 0
  AND `event_param2` = 1
  AND `action_type` = 33
  AND `action_param1` = 33708
  AND `target_type` = 12
  AND `target_param1` = 1;

COMMIT;
