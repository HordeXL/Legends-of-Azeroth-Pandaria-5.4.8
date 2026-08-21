-- Move Nalak's Boss Bot Caller to the exact safe ground point saved when
-- Palstest logged out beside Nalak. The point is about 93 yards from the
-- active Nalak spawn in two dimensions (about 100 yards in three dimensions),
-- so it remains well inside the configured 180-yard boss search radius.
-- No spawn is deleted and no boss data is changed.

START TRANSACTION;

UPDATE `creature`
   SET `zoneId` = 6507,
       `areaId` = 6591,
       `position_x` = 7040.92,
       `position_y` = 5227.69,
       `position_z` = 84.2521,
       `orientation` = 5.38619
 WHERE `guid` = 4000102
   AND `id` = 990912
   AND `map` = 1064
   AND ABS(`position_x` - 6972.62) < 0.01
   AND ABS(`position_y` - 5184.14) < 0.01;

UPDATE `playerbot_world_boss_caller`
   SET `rally_x` = 7040.92,
       `rally_y` = 5227.69,
       `rally_z` = 84.2521,
       `rally_o` = 5.38619
 WHERE `guid` = 4000102
   AND `boss_entry` = 69099
   AND ABS(`rally_x` - 6972.62) < 0.01
   AND ABS(`rally_y` - 5184.14) < 0.01;

COMMIT;

SELECT `guid`, `map`, `zoneId`, `areaId`, `position_x`, `position_y`,
       `position_z`, `orientation`
  FROM `creature`
 WHERE `guid` = 4000102;

SELECT `guid`, `boss_entry`, `boss_search_radius`,
       `rally_x`, `rally_y`, `rally_z`, `rally_o`
  FROM `playerbot_world_boss_caller`
 WHERE `guid` = 4000102;
