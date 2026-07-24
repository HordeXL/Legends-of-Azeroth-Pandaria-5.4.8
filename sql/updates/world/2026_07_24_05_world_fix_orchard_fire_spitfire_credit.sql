-- Quest 29585 "Spitfire":
-- use the Build-18414 quest-credit spell instead of a manual SmartAI credit.
--
-- Quest item 72578 (Nectarbreeze Cider) casts spell 102375 on Orchard Fire
-- 54780. The quest objective requires 12 credits for creature 54789
-- (Orchard Fire Kill Credit). Build-18414 spell 102384 contains exactly one
-- SPELL_EFFECT_KILL_CREDIT2 effect for creature 54789 and no other effects.
--
-- Preserve the existing linked action chain: after credit, the Orchard Fire
-- applies extinguished aura 102372 and despawns after 2 seconds.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_orchard_fire_spitfire_20260724`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_orchard_fire_spitfire_20260724`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 54780
  AND `s`.`source_type` = 0
  AND `s`.`id` = 0
  AND `s`.`link` = 1
  AND `s`.`event_type` = 8
  AND `s`.`event_param1` = 102375
  AND `s`.`event_param3` = 2000
  AND `s`.`event_param4` = 2000
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 54789
  AND `s`.`target_type` = 7;

START TRANSACTION;

SET @orchard_fire_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_orchard_fire_spitfire_20260724`
);

UPDATE `smart_scripts`
SET `action_type` = 85,
    `action_param1` = 102384,
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
    `comment` = 'Orchard Fire - player casts Spitfire credit spell'
WHERE @orchard_fire_backup_ok = 1
  AND `entryorguid` = 54780
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 1
  AND `event_type` = 8
  AND `event_param1` = 102375
  AND `event_param3` = 2000
  AND `event_param4` = 2000
  AND `action_type` = 33
  AND `action_param1` = 54789
  AND `target_type` = 7;

COMMIT;
