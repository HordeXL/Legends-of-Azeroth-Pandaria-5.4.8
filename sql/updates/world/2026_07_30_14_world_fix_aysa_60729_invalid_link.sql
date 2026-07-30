-- Aysa Cloudsinger (60729): remove the invalid link from SmartAI row 18.
--
-- Row 18 is already a SMART_EVENT_LINK action chained from row 17 and makes
-- Aysa jump to the coordinates of waypoint 4. Its link field incorrectly
-- points to row 19, but row 19 is an independent
-- SMART_EVENT_WAYPOINT_ENDED event, not another SMART_EVENT_LINK row.
-- SmartScript therefore rejects link 19 at runtime.
--
-- Keep row 19 unchanged: after waypoint path 60729 ends at point 4, it
-- despawns Aysa as intended. Only the structurally invalid extra link is
-- cleared.

CREATE TABLE IF NOT EXISTS
    `_backup_smart_scripts_aysa_60729_invalid_link_20260730`
LIKE `smart_scripts`;

INSERT INTO `_backup_smart_scripts_aysa_60729_invalid_link_20260730`
SELECT `smart`.*
FROM `smart_scripts` AS `smart`
WHERE `smart`.`entryorguid` = 60729
  AND `smart`.`source_type` = 0
  AND `smart`.`id` = 18
  AND `smart`.`link` = 19
  AND `smart`.`event_type` = 61
  AND `smart`.`action_type` = 97
  AND `smart`.`target_type` = 1
  AND ABS(`smart`.`target_x` - 239.453) < 0.001
  AND ABS(`smart`.`target_y` - 3942.2) < 0.001
  AND ABS(`smart`.`target_z` - 62.5987) < 0.001
ON DUPLICATE KEY UPDATE
    `entryorguid` = VALUES(`entryorguid`);

START TRANSACTION;

SET @aysa_60729_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`entryorguid` = 60729
               AND `source_type` = 0
               AND `id` = 18
               AND `link` = 19
               AND `event_type` = 61
               AND `action_type` = 97
               AND `target_type` = 1
               AND ABS(`target_x` - 239.453) < 0.001
               AND ABS(`target_y` - 3942.2) < 0.001
               AND ABS(`target_z` - 62.5987) < 0.001) = 1
    FROM `_backup_smart_scripts_aysa_60729_invalid_link_20260730`
);

UPDATE `smart_scripts`
SET `link` = 0
WHERE @aysa_60729_backup_ok = 1
  AND `entryorguid` = 60729
  AND `source_type` = 0
  AND `id` = 18
  AND `link` = 19
  AND `event_type` = 61
  AND `action_type` = 97
  AND `target_type` = 1
  AND ABS(`target_x` - 239.453) < 0.001
  AND ABS(`target_y` - 3942.2) < 0.001
  AND ABS(`target_z` - 62.5987) < 0.001;

COMMIT;
