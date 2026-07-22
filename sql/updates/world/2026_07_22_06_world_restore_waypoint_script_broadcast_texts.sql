-- Restore TALK text ids for waypoint actions whose identity is proven by the
-- same NPC, waypoint point and coordinates in both the preserved SkyFire
-- 5.4.8 world and TDB 4.3.4 world databases.
--
-- SkyFire stores the old db_script_string ids.  TDB maps the same source
-- actions to the broadcast_text ids used by this core.  Every target
-- broadcast_text row is also required to exist locally before any update.
-- No waypoint or script row is deleted.

CREATE TABLE IF NOT EXISTS `_backup_waypoint_scripts_talk_20260722`
LIKE `waypoint_scripts`;

INSERT IGNORE INTO `_backup_waypoint_scripts_talk_20260722`
SELECT `ws`.*
FROM `waypoint_scripts` AS `ws`
WHERE `ws`.`id` IN
      (336, 337, 351, 352, 354, 426, 427, 428, 446,
       460, 491, 499, 500, 501, 537, 538, 539, 540)
  AND `ws`.`delay` = 0
  AND `ws`.`command` = 0
  AND `ws`.`datalong` = 0
  AND `ws`.`datalong2` = 0
  AND `ws`.`dataint` = 0
  AND `ws`.`x` = 0
  AND `ws`.`y` = 0
  AND `ws`.`z` = 0
  AND `ws`.`o` = 0
  AND `ws`.`Comment` = '';

START TRANSACTION;

SET @waypoint_talk_backup_ok :=
(
    SELECT COUNT(*) = 26
       AND SUM(`id` = 336) = 3
       AND SUM(`id` = 337) = 2
       AND SUM(`id` = 351) = 1
       AND SUM(`id` = 352) = 2
       AND SUM(`id` = 354) = 1
       AND SUM(`id` = 426) = 1
       AND SUM(`id` = 427) = 1
       AND SUM(`id` = 428) = 1
       AND SUM(`id` = 446) = 1
       AND SUM(`id` = 460) = 1
       AND SUM(`id` = 491) = 1
       AND SUM(`id` = 499) = 2
       AND SUM(`id` = 500) = 2
       AND SUM(`id` = 501) = 2
       AND SUM(`id` = 537) = 2
       AND SUM(`id` = 538) = 1
       AND SUM(`id` = 539) = 1
       AND SUM(`id` = 540) = 1
    FROM `_backup_waypoint_scripts_talk_20260722`
);

SET @waypoint_talk_broadcasts_ok :=
(
    SELECT COUNT(*) = 18
    FROM `broadcast_text`
    WHERE `ID` IN
          (10152, 13572, 13576, 13580, 14565, 14567,
           15119, 15144, 17035, 17045, 17056, 17563,
           17569, 18816, 22206, 22211, 22216, 23842)
);

UPDATE `waypoint_scripts` AS `ws`
JOIN
(
    SELECT 336 AS `script_id`, 17569 AS `text_id`, 54830 AS `path_id`, 2 AS `point`, 18667 AS `npc_entry`
    UNION ALL SELECT 337, 17563, 54830, 3, 18667
    UNION ALL SELECT 351, 17045, 57279, 2, 19612
    UNION ALL SELECT 352, 17056, 57279, 3, 19612
    UNION ALL SELECT 354, 23842, 58012, 2, 24688
    UNION ALL SELECT 426, 18816, 62272, 5, 21151
    UNION ALL SELECT 427, 14565, 62389, 16, 17901
    UNION ALL SELECT 428, 14567, 62389, 18, 17901
    UNION ALL SELECT 446, 17035, 65722, 5, 19610
    UNION ALL SELECT 460, 15119, 65967, 5, 18296
    UNION ALL SELECT 491, 15144, 70270, 1, 18302
    UNION ALL SELECT 499, 13572, 72126, 1, 17222
    UNION ALL SELECT 500, 13580, 72126, 3, 17222
    UNION ALL SELECT 501, 13576, 72126, 5, 17222
    UNION ALL SELECT 537, 10152, 77841, 3, 14828
    UNION ALL SELECT 538, 22216, 78650, 1, 23718
    UNION ALL SELECT 539, 22211, 78650, 2, 23718
    UNION ALL SELECT 540, 22206, 78650, 3, 23718
) AS `source`
  ON `source`.`script_id` = `ws`.`id`
JOIN `waypoint_data` AS `wd`
  ON `wd`.`action` = `source`.`script_id`
 AND `wd`.`id` = `source`.`path_id`
 AND `wd`.`point` = `source`.`point`
JOIN `creature_addon` AS `ca`
  ON `ca`.`path_id` = `source`.`path_id`
JOIN `creature` AS `c`
  ON `c`.`guid` = `ca`.`guid`
 AND `c`.`id` = `source`.`npc_entry`
JOIN `broadcast_text` AS `bt`
  ON `bt`.`ID` = `source`.`text_id`
SET `ws`.`dataint` = `source`.`text_id`
WHERE @waypoint_talk_backup_ok = 1
  AND @waypoint_talk_broadcasts_ok = 1
  AND `ws`.`delay` = 0
  AND `ws`.`command` = 0
  AND `ws`.`datalong` = 0
  AND `ws`.`datalong2` = 0
  AND `ws`.`dataint` = 0
  AND `ws`.`x` = 0
  AND `ws`.`y` = 0
  AND `ws`.`z` = 0
  AND `ws`.`o` = 0
  AND `ws`.`Comment` = '';

COMMIT;
