-- Quest 25299 "Mental Training: Speaking the Truth to Power":
-- remove Instructor Mylva's unrelated automatic proximity credit.
--
-- Quest item 52828 casts spell 73984.  Its Build-18414
-- SPELL_AURA_OVERRIDE_SPELLS effect uses OverrideSpellData id 267, which
-- gives the player answer spells 73982 and 73983 plus exit spell 76643.
-- The two answer spells trigger 74010/74012, and both of those grant one
-- Mental Training credit (39824).  The core implements this override-spell
-- aura and temporary spell bar directly.
--
-- The SmartAI row below bypasses that complete mechanism by granting one
-- 39824 credit every second to every player within 50 yards, regardless of
-- quest-item use or answer selection.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_mylva_mental_credit_20260724`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_mylva_mental_credit_20260724`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 39413
  AND `s`.`source_type` = 0
  AND `s`.`id` = 1
  AND `s`.`link` = 0
  AND `s`.`event_type` = 1
  AND `s`.`event_param1` = 0
  AND `s`.`event_param2` = 0
  AND `s`.`event_param3` = 1000
  AND `s`.`event_param4` = 1000
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 39824
  AND `s`.`target_type` = 17
  AND `s`.`target_param1` = 0
  AND `s`.`target_param2` = 50;

START TRANSACTION;

SET @mylva_mental_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_mylva_mental_credit_20260724`
);

DELETE FROM `smart_scripts`
WHERE @mylva_mental_backup_ok = 1
  AND `entryorguid` = 39413
  AND `source_type` = 0
  AND `id` = 1
  AND `link` = 0
  AND `event_type` = 1
  AND `event_param1` = 0
  AND `event_param2` = 0
  AND `event_param3` = 1000
  AND `event_param4` = 1000
  AND `action_type` = 33
  AND `action_param1` = 39824
  AND `target_type` = 17
  AND `target_param1` = 0
  AND `target_param2` = 50;

COMMIT;
