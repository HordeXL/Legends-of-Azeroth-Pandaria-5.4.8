-- Quest 25236 "Thunder Down Under":
-- restore the complete Build-18414 tether spell after the spell-click shock.
--
-- Drowned Thunder Lizard 39464 is spell-clickable with spell 73958
-- ("Lightning Discharge"). With cast_flags 1, the player is the caster, so
-- that player is also SmartAI's action invoker. Build-18414 spell 73945
-- ("Attach Tether") summons Hulking Orcish Laborer 39465 and grants the
-- quest credit for creature 39464. The old direct Action 33 granted only the
-- numeric credit and skipped the tether/laborer part of the spell.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_drowned_thunder_lizard_20260724`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_drowned_thunder_lizard_20260724`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 39464
  AND `s`.`source_type` = 0
  AND `s`.`id` = 0
  AND `s`.`link` = 1
  AND `s`.`event_type` = 8
  AND `s`.`event_param1` = 73958
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 39464
  AND `s`.`target_type` = 7;

START TRANSACTION;

SET @drowned_thunder_lizard_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_drowned_thunder_lizard_20260724`
);

UPDATE `smart_scripts`
SET `action_type` = 85,
    `action_param1` = 73945,
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
    `comment` = 'Drowned Thunder Lizard - player casts complete Attach Tether spell'
WHERE @drowned_thunder_lizard_backup_ok = 1
  AND `entryorguid` = 39464
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 1
  AND `event_type` = 8
  AND `event_param1` = 73958
  AND `action_type` = 33
  AND `action_param1` = 39464
  AND `target_type` = 7;

COMMIT;
