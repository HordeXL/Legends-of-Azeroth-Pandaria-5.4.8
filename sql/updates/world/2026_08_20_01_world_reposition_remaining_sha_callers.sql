-- Move the remaining four Sha of Anger Boss Bot Callers away from their
-- corresponding pool spawns.  They were originally placed only 25 yards from
-- the boss and could aggro Sha before the player could open the gossip menu.
--
-- Caller 4000097 (Sha site 1) was corrected separately by
-- 2026_08_20_00_world_reposition_boss_bot_callers.sql and is intentionally
-- not changed here.  Every destination below is anchored to existing local
-- terrain spawns and remains inside the configured 180-yard boss search.

UPDATE `creature`
   SET `position_x` = 2227.68, `position_y` = 630.00,
       `position_z` = 496.63, `orientation` = 6.032
 WHERE `guid` = 4000098 AND `id` = 990912
   AND ABS(`position_x` - 2386.80) < 0.01
   AND ABS(`position_y` - 595.601) < 0.01;

UPDATE `playerbot_world_boss_caller`
   SET `rally_x` = 2227.68, `rally_y` = 630.00,
       `rally_z` = 496.63, `rally_o` = 6.032
 WHERE `guid` = 4000098 AND `boss_entry` = 60491;

UPDATE `creature`
   SET `position_x` = 2877.48, `position_y` = 1693.28,
       `position_z` = 643.21, `orientation` = 3.012
 WHERE `guid` = 4000099 AND `id` = 990912
   AND ABS(`position_x` - 2762.45) < 0.01
   AND ABS(`position_y` - 1711.46) < 0.01;

UPDATE `playerbot_world_boss_caller`
   SET `rally_x` = 2877.48, `rally_y` = 1693.28,
       `rally_z` = 643.21, `rally_o` = 3.012
 WHERE `guid` = 4000099 AND `boss_entry` = 60491;

UPDATE `creature`
   SET `position_x` = 2793.05, `position_y` = 1498.54,
       `position_z` = 648.81, `orientation` = 6.113
 WHERE `guid` = 4000100 AND `id` = 990912
   AND ABS(`position_x` - 2949.01) < 0.01
   AND ABS(`position_y` - 1476.00) < 0.01;

UPDATE `playerbot_world_boss_caller`
   SET `rally_x` = 2793.05, `rally_y` = 1498.54,
       `rally_z` = 648.81, `rally_o` = 6.113
 WHERE `guid` = 4000100 AND `boss_entry` = 60491;

UPDATE `creature`
   SET `position_x` = 2828.36, `position_y` = 394.00,
       `position_z` = 506.86, `orientation` = 0.102
 WHERE `guid` = 4000101 AND `id` = 990912
   AND ABS(`position_x` - 2980.40) < 0.01
   AND ABS(`position_y` - 407.047) < 0.01;

UPDATE `playerbot_world_boss_caller`
   SET `rally_x` = 2828.36, `rally_y` = 394.00,
       `rally_z` = 506.86, `rally_o` = 0.102
 WHERE `guid` = 4000101 AND `boss_entry` = 60491;

SELECT `guid`, `position_x`, `position_y`, `position_z`, `orientation`
  FROM `creature`
 WHERE `guid` BETWEEN 4000097 AND 4000101
 ORDER BY `guid`;

SELECT `guid`, `boss_entry`, `boss_search_radius`,
       `rally_x`, `rally_y`, `rally_z`, `rally_o`
  FROM `playerbot_world_boss_caller`
 WHERE `guid` BETWEEN 4000097 AND 4000101
 ORDER BY `guid`;
