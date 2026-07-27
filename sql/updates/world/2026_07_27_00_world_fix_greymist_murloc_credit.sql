-- Quest 13560 "An Ocean Not So Deep":
-- use the dedicated Build-18414 Murloc Kill Credit spell.
--
-- The death event's invoker is the killing unit. Spell 62683 targets its
-- caster and master, so a player killer credits itself while a pet killer
-- credits its owning player. Preserve all combat/follow behavior and change
-- only the two manual death credits.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_greymist_murloc_credit_20260727`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_greymist_murloc_credit_20260727`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` IN (33262, 33277)
  AND `s`.`source_type` = 0
  AND `s`.`id` = 3
  AND `s`.`link` = 0
  AND `s`.`event_type` = 6
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 32852
  AND `s`.`target_type` = 7;

START TRANSACTION;

SET @greymist_murloc_backup_ok :=
(
    SELECT COUNT(*) = 2
    FROM `_backup_smart_scripts_greymist_murloc_credit_20260727`
);

UPDATE `smart_scripts`
SET `action_type` = 85,
    `action_param1` = 62683,
    `action_param2` = 1,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = CASE `entryorguid`
        WHEN 33262 THEN 'Greymist Tidehunter - on death make killer cast Murloc Kill Credit'
        WHEN 33277 THEN 'Greymist Warrior - on death make killer cast Murloc Kill Credit'
        ELSE `comment`
    END
WHERE @greymist_murloc_backup_ok = 1
  AND `entryorguid` IN (33262, 33277)
  AND `source_type` = 0
  AND `id` = 3
  AND `link` = 0
  AND `event_type` = 6
  AND `action_type` = 33
  AND `action_param1` = 32852
  AND `target_type` = 7;

COMMIT;
