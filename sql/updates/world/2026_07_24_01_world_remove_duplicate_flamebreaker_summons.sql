-- Quest 25323 "Flamebreaker": remove the old SmartAI fallback that
-- duplicates effects already performed by the registered item spell script.
--
-- spell_item_flameseers_staff_flamebreaker makes the player cast 74723 on
-- Blazebound Elemental (38896), then kills the elemental.  Spell 74723 itself
-- summons 6-10 Unbound Flame Spirits (40065).  SpellMgr corrects the client
-- DBC summon entry from 40080 to 40065 for this exact quest spell.
--
-- The seven exact duplicate SmartAI rows are preserved before removal.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_flamebreaker_20260724`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_flamebreaker_20260724`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 38896
  AND `s`.`source_type` = 0
  AND
  (
      (`s`.`id` = 0 AND `s`.`link` = 1 AND `s`.`event_type` = 8
       AND `s`.`event_param1` = 74723
       AND `s`.`action_type` = 12 AND `s`.`action_param1` = 40065) OR
      (`s`.`id` = 1 AND `s`.`link` = 2 AND `s`.`event_type` = 61
       AND `s`.`action_type` = 12 AND `s`.`action_param1` = 40065) OR
      (`s`.`id` = 2 AND `s`.`link` = 3 AND `s`.`event_type` = 61
       AND `s`.`action_type` = 12 AND `s`.`action_param1` = 40065) OR
      (`s`.`id` = 3 AND `s`.`link` = 4 AND `s`.`event_type` = 61
       AND `s`.`action_type` = 12 AND `s`.`action_param1` = 40065) OR
      (`s`.`id` = 4 AND `s`.`link` = 5 AND `s`.`event_type` = 61
       AND `s`.`action_type` = 12 AND `s`.`action_param1` = 40065) OR
      (`s`.`id` = 5 AND `s`.`link` = 6 AND `s`.`event_type` = 61
       AND `s`.`action_type` = 12 AND `s`.`action_param1` = 40065) OR
      (`s`.`id` = 6 AND `s`.`link` = 0 AND `s`.`event_type` = 61
       AND `s`.`action_type` = 37)
  );

START TRANSACTION;

SET @flamebreaker_backup_ok :=
(
    SELECT COUNT(*) = 7
    FROM `_backup_smart_scripts_flamebreaker_20260724`
);

DELETE FROM `smart_scripts`
WHERE @flamebreaker_backup_ok = 1
  AND `entryorguid` = 38896
  AND `source_type` = 0
  AND
  (
      (`id` = 0 AND `link` = 1 AND `event_type` = 8
       AND `event_param1` = 74723
       AND `action_type` = 12 AND `action_param1` = 40065) OR
      (`id` = 1 AND `link` = 2 AND `event_type` = 61
       AND `action_type` = 12 AND `action_param1` = 40065) OR
      (`id` = 2 AND `link` = 3 AND `event_type` = 61
       AND `action_type` = 12 AND `action_param1` = 40065) OR
      (`id` = 3 AND `link` = 4 AND `event_type` = 61
       AND `action_type` = 12 AND `action_param1` = 40065) OR
      (`id` = 4 AND `link` = 5 AND `event_type` = 61
       AND `action_type` = 12 AND `action_param1` = 40065) OR
      (`id` = 5 AND `link` = 6 AND `event_type` = 61
       AND `action_type` = 12 AND `action_param1` = 40065) OR
      (`id` = 6 AND `link` = 0 AND `event_type` = 61
       AND `action_type` = 37)
  );

COMMIT;
