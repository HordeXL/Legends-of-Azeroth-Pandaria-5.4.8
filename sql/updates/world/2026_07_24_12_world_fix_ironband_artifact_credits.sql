-- Quest 13650 "Keep Your Hands Off The Goods!":
-- use the three dedicated Build-18414 artifact credit spells.
--
-- The invisible artifact bunnies already check every second for players
-- within ten yards. Each dedicated spell contains exactly one kill-credit2
-- effect aimed at the selected unit:
--   63073 -> 33485 (Sandal / Upturned Giant)
--   63074 -> 33486 (Liberty / Overdressed Woman)
--   63075 -> 33487 (Tablet / Broken Tablet)
-- Preserve the existing proximity events and replace only the manual
-- SmartAI credits with the matching complete client spells.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_ironband_artifacts_20260724`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_ironband_artifacts_20260724`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` IN (33485, 33486, 33487)
  AND `s`.`source_type` = 0
  AND `s`.`id` = 0
  AND `s`.`link` = 0
  AND `s`.`event_type` = 1
  AND `s`.`event_param1` = 0
  AND `s`.`event_param2` = 0
  AND `s`.`event_param3` = 1000
  AND `s`.`event_param4` = 1000
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = `s`.`entryorguid`
  AND `s`.`target_type` = 17
  AND `s`.`target_param1` = 0
  AND `s`.`target_param2` = 10;

START TRANSACTION;

SET @ironband_artifact_backup_ok :=
(
    SELECT COUNT(*) = 3
    FROM `_backup_smart_scripts_ironband_artifacts_20260724`
);

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = CASE `entryorguid`
        WHEN 33485 THEN 63073
        WHEN 33486 THEN 63074
        WHEN 33487 THEN 63075
    END,
    `action_param2` = 1,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = CASE `entryorguid`
        WHEN 33485 THEN 'Ironband Sandal Artifact Bunny - cast dedicated credit spell on nearby player'
        WHEN 33486 THEN 'Ironband Liberty Artifact Bunny - cast dedicated credit spell on nearby player'
        WHEN 33487 THEN 'Ironband Tablet Artifact Bunny - cast dedicated credit spell on nearby player'
    END
WHERE @ironband_artifact_backup_ok = 1
  AND `entryorguid` IN (33485, 33486, 33487)
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 0
  AND `event_type` = 1
  AND `event_param1` = 0
  AND `event_param2` = 0
  AND `event_param3` = 1000
  AND `event_param4` = 1000
  AND `action_type` = 33
  AND `action_param1` = `entryorguid`
  AND `target_type` = 17
  AND `target_param1` = 0
  AND `target_param2` = 10;

COMMIT;
