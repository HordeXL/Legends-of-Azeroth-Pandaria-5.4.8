-- Quests 13886/13888 "Vortex":
-- use the dedicated Build-18414 Lord Magmathar credit spell.
--
-- The player casts spell 65186 and therefore owns the summoned Whirling
-- Vortex. Lord Magmathar sends data 0/1 to that Vortex on death. Spell
-- 65237 grants credit 34333 to its caster's master, so the Vortex must cast
-- it on itself. Preserve the complete vehicle path, combat and cleanup chain.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_lord_magmathar_vortex_credit_20260727`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_lord_magmathar_vortex_credit_20260727`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 34322
  AND `s`.`source_type` = 0
  AND `s`.`id` = 7
  AND `s`.`link` = 8
  AND `s`.`event_type` = 38
  AND `s`.`event_param1` = 0
  AND `s`.`event_param2` = 1
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 34333
  AND `s`.`target_type` = 21
  AND `s`.`target_param1` = 5;

START TRANSACTION;

SET @lord_magmathar_vortex_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_lord_magmathar_vortex_credit_20260727`
);

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 65237,
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
    `comment` = 'Whirling Vortex - on Lord Magmathar death cast dedicated credit on owner'
WHERE @lord_magmathar_vortex_backup_ok = 1
  AND `entryorguid` = 34322
  AND `source_type` = 0
  AND `id` = 7
  AND `link` = 8
  AND `event_type` = 38
  AND `event_param1` = 0
  AND `event_param2` = 1
  AND `action_type` = 33
  AND `action_param1` = 34333
  AND `target_type` = 21
  AND `target_param1` = 5;

COMMIT;
