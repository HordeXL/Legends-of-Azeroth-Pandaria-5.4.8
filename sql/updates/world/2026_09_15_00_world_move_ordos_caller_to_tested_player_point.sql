-- Move Ordos's Boss Bot Caller to the exact point occupied by Grotroz during
-- the live positioning test. The point is about 52 yards from Ordos and
-- remains well inside the configured 180-yard boss search radius.
-- No spawn is deleted and no boss data is changed.

START TRANSACTION;

UPDATE `creature`
   SET `zoneId` = 6757,
       `areaId` = 6823,
       `position_x` = -97.3675,
       `position_y` = -5395.32,
       `position_z` = 150.105,
       `orientation` = 6.06367
 WHERE `guid` = 4000108
   AND `id` = 990912
   AND `map` = 870
   AND ABS(`position_x` - (-71.148)) < 0.01
   AND ABS(`position_y` - (-5402.76)) < 0.01;

UPDATE `playerbot_world_boss_caller`
   SET `rally_x` = -97.3675,
       `rally_y` = -5395.32,
       `rally_z` = 150.105,
       `rally_o` = 6.06367
 WHERE `guid` = 4000108
   AND `boss_entry` = 72057
   AND ABS(`rally_x` - (-71.148)) < 0.01
   AND ABS(`rally_y` - (-5402.76)) < 0.01;

COMMIT;

SELECT `guid`, `map`, `zoneId`, `areaId`, `position_x`, `position_y`,
       `position_z`, `orientation`
  FROM `creature`
 WHERE `guid` = 4000108;

SELECT `guid`, `boss_entry`, `boss_search_radius`,
       `rally_x`, `rally_y`, `rally_z`, `rally_o`
  FROM `playerbot_world_boss_caller`
 WHERE `guid` = 4000108;
