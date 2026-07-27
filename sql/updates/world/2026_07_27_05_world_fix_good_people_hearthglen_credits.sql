-- Quest 27153 "The Good People of Hearthglen":
-- replace four manual gossip credits with their exact Build-18414 personal
-- credit spells. Preserve each quest condition, gossip option, link, and
-- linked close-gossip action.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_good_people_hearthglen_20260727`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_good_people_hearthglen_20260727`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`source_type` = 0
  AND `s`.`id` = 0
  AND `s`.`link` = 1
  AND `s`.`event_type` = 62
  AND `s`.`target_type` = 7
  AND `s`.`action_type` = 33
  AND
  (
       (`s`.`entryorguid` = 45148 AND `s`.`action_param1` = 45148)
    OR (`s`.`entryorguid` = 45149 AND `s`.`action_param1` = 45149)
    OR (`s`.`entryorguid` = 45150 AND `s`.`action_param1` = 45150)
    OR (`s`.`entryorguid` = 45151 AND `s`.`action_param1` = 45151)
  );

START TRANSACTION;

SET @good_people_hearthglen_backup_ok :=
(
    SELECT COUNT(*) = 4
    FROM `_backup_smart_scripts_good_people_hearthglen_20260727`
);

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 84312,
    `action_param2` = 2,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Morris Vant - Gossip Select - Cast dedicated Vant credit on player'
WHERE @good_people_hearthglen_backup_ok = 1
  AND `entryorguid` = 45148
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 1
  AND `event_type` = 62
  AND `event_param1` = 11934
  AND `event_param2` = 0
  AND `action_type` = 33
  AND `action_param1` = 45148
  AND `target_type` = 7;

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 84313,
    `action_param2` = 2,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Outfitter Mendelev - Gossip Select - Cast dedicated Mendelev credit on player'
WHERE @good_people_hearthglen_backup_ok = 1
  AND `entryorguid` = 45149
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 1
  AND `event_type` = 62
  AND `event_param1` = 11936
  AND `event_param2` = 0
  AND `action_type` = 33
  AND `action_param1` = 45149
  AND `target_type` = 7;

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 84315,
    `action_param2` = 2,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Bree Ironstock - Gossip Select - Cast dedicated Bree credit on player'
WHERE @good_people_hearthglen_backup_ok = 1
  AND `entryorguid` = 45150
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 1
  AND `event_type` = 62
  AND `event_param1` = 11938
  AND `event_param2` = 0
  AND `action_type` = 33
  AND `action_param1` = 45150
  AND `target_type` = 7;

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 84316,
    `action_param2` = 2,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'High Cleric Alphus - Gossip Select - Cast dedicated Alphus credit on player'
WHERE @good_people_hearthglen_backup_ok = 1
  AND `entryorguid` = 45151
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 1
  AND `event_type` = 62
  AND `event_param1` = 11940
  AND `event_param2` = 0
  AND `action_type` = 33
  AND `action_param1` = 45151
  AND `target_type` = 7;

COMMIT;
