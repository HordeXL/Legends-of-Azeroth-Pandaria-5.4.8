-- Restore five waypoint TALK rows whose original text, owning NPC, waypoint
-- point and active Build-18414 broadcast_text can all be proven.
--
-- The preserved 2024 Pandaria base at
-- C:/wamp64/www/pandaria_5.4.8/sql/base/2024_08_01_world.sql retains the old
-- script-string ids and text.  The active creature_text table independently
-- maps the same NPC lines to the broadcast_text ids required by this core.
-- No waypoint, script or text row is deleted.

CREATE TABLE IF NOT EXISTS `_backup_waypoint_scripts_talk_part2_20260723`
LIKE `waypoint_scripts`;

INSERT IGNORE INTO `_backup_waypoint_scripts_talk_part2_20260723`
SELECT `ws`.*
FROM `waypoint_scripts` AS `ws`
WHERE `ws`.`guid` IN (2, 99, 140, 141, 300)
  AND `ws`.`id` IN (24, 156, 212, 213)
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

SET @waypoint_talk_part2_backup_ok :=
(
    SELECT COUNT(*) = 5
       AND SUM(`guid` = 2   AND `id` = 24)  = 1
       AND SUM(`guid` = 300 AND `id` = 24)  = 1
       AND SUM(`guid` = 99  AND `id` = 156) = 1
       AND SUM(`guid` = 140 AND `id` = 212) = 1
       AND SUM(`guid` = 141 AND `id` = 213) = 1
    FROM `_backup_waypoint_scripts_talk_part2_20260723`
);

SET @waypoint_talk_part2_broadcasts_ok :=
(
    SELECT COUNT(*) = 5
    FROM `broadcast_text`
    WHERE `ID` IN (2981, 3001, 4287, 10149, 10152)
);

UPDATE `waypoint_scripts` AS `ws`
JOIN
(
    SELECT 24 AS `script_id`, 2 AS `script_guid`, 10152 AS `text_id`,
           4961 AS `path_id`, 3 AS `point`, 14828 AS `npc_entry`
    UNION ALL
    SELECT 24, 300, 10149, 4961, 3, 14828
    UNION ALL
    SELECT 156, 99, 4287, 9663, 16, 8256
    UNION ALL
    SELECT 212, 140, 2981, 46686, 1, 6909
    UNION ALL
    SELECT 213, 141, 3001, 46686, 2, 6909
) AS `source`
  ON `source`.`script_id` = `ws`.`id`
 AND `source`.`script_guid` = `ws`.`guid`
JOIN `waypoint_data` AS `wd`
  ON `wd`.`action` = `source`.`script_id`
 AND `wd`.`id` = `source`.`path_id`
 AND `wd`.`point` = `source`.`point`
JOIN `creature_addon` AS `ca`
  ON `ca`.`path_id` = `source`.`path_id`
JOIN `creature` AS `c`
  ON `c`.`guid` = `ca`.`guid`
 AND `c`.`id` = `source`.`npc_entry`
JOIN `creature_text` AS `ct`
  ON `ct`.`CreatureID` = `source`.`npc_entry`
 AND `ct`.`BroadcastTextId` = `source`.`text_id`
JOIN `broadcast_text` AS `bt`
  ON `bt`.`ID` = `source`.`text_id`
SET `ws`.`dataint` = `source`.`text_id`
WHERE @waypoint_talk_part2_backup_ok = 1
  AND @waypoint_talk_part2_broadcasts_ok = 1
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
