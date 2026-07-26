-- Quests 29398 / 29416 "Fencing the Goods":
-- use the dedicated Build-18414 completion spell for both factions.
--
-- Spell 100529 ("Fencing the Goods Credit") contains exactly one
-- kill-credit2 effect for 53978. Its source-area target has a 20-yard
-- radius and the core applies the credit effect only to player targets.
-- Keep each NPC's existing gossip/dialogue timing and replace only the
-- manual SmartAI credit after the relevant gossip sequence.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_fencing_goods_20260724`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_fencing_goods_20260724`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 8719
  AND `s`.`source_type` = 0
  AND `s`.`id` = 4
  AND `s`.`link` = 0
  AND `s`.`event_type` = 61
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 53978
  AND `s`.`target_type` = 7;

INSERT IGNORE INTO `_backup_smart_scripts_fencing_goods_20260724`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` = 44866
  AND `s`.`source_type` = 0
  AND `s`.`id` = 0
  AND `s`.`link` = 1
  AND `s`.`event_type` = 62
  AND `s`.`event_param1` = 12949
  AND `s`.`event_param2` = 0
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 53978
  AND `s`.`target_type` = 7;

START TRANSACTION;

SET @fencing_goods_backup_ok :=
(
    SELECT COUNT(*) = 2
    FROM `_backup_smart_scripts_fencing_goods_20260724`
);

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 100529,
    `action_param2` = 1,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Auctioneer Fitch - after dialogue cast Fencing the Goods credit spell'
WHERE @fencing_goods_backup_ok = 1
  AND `entryorguid` = 8719
  AND `source_type` = 0
  AND `id` = 4
  AND `link` = 0
  AND `event_type` = 61
  AND `action_type` = 33
  AND `action_param1` = 53978
  AND `target_type` = 7;

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 100529,
    `action_param2` = 1,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Auctioneer Drezmit - on gossip cast Fencing the Goods credit spell'
WHERE @fencing_goods_backup_ok = 1
  AND `entryorguid` = 44866
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 1
  AND `event_type` = 62
  AND `event_param1` = 12949
  AND `event_param2` = 0
  AND `action_type` = 33
  AND `action_param1` = 53978
  AND `target_type` = 7;

COMMIT;
