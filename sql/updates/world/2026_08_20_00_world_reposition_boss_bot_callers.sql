-- Reposition three Boss Bot Callers whose original boss-relative coordinates
-- were unsafe or unusable in game.
--
-- * Sha of Anger (current spawn 1958.73, 1634.28, 482.576): move the caller
--   from 25 yards to about 162 yards away, while keeping it inside the
--   configured 180-yard boss search radius.
-- * Nalak: move the caller off the elevated boss spawn to stable ground beside
--   the nearest Spirit Healer. The new point remains about 151 yards (3D) from
--   Nalak and inside the configured 180-yard boss search radius.
-- * Oondasta: move the caller beside the nearby Spirit Healer, about 82 yards
--   from the boss and inside the configured 220-yard boss search radius.
--
-- Ordos and all other callers are intentionally unchanged. No row is deleted.

START TRANSACTION;

-- Sha of Anger, current active spawn site in Kun-Lai Summit.
UPDATE `creature`
   SET `position_x` = 1940.93,
       `position_y` = 1473.59,
       `position_z` = 482.748,
       `orientation` = 1.460474
 WHERE `guid` = 4000097
   AND `id` = 990912
   AND `map` = 870
   AND ABS(`position_x` - 1983.73) < 0.01
   AND ABS(`position_y` - 1634.28) < 0.01;

UPDATE `playerbot_world_boss_caller`
   SET `rally_x` = 1940.93,
       `rally_y` = 1473.59,
       `rally_z` = 482.748,
       `rally_o` = 1.460474
 WHERE `guid` = 4000097
   AND `boss_entry` = 60491
   AND ABS(`rally_x` - 1983.73) < 0.01
   AND ABS(`rally_y` - 1634.28) < 0.01;

-- Nalak, stable ground beside Spirit Healer spawn 515321.
UPDATE `creature`
   SET `zoneId` = 6507,
       `areaId` = 6591,
       `position_x` = 6972.62,
       `position_y` = 5184.14,
       `position_z` = 67.4448,
       `orientation` = 6.174452
 WHERE `guid` = 4000102
   AND `id` = 990912
   AND `map` = 1064
   AND ABS(`position_x` - 7082.96) < 0.01
   AND ABS(`position_y` - 5168.82) < 0.01;

UPDATE `playerbot_world_boss_caller`
   SET `rally_x` = 6972.62,
       `rally_y` = 5184.14,
       `rally_z` = 67.4448,
       `rally_o` = 6.174452
 WHERE `guid` = 4000102
   AND `boss_entry` = 69099
   AND ABS(`rally_x` - 7082.96) < 0.01
   AND ABS(`rally_y` - 5168.82) < 0.01;

-- Oondasta, beside Spirit Healer spawn 511213.
UPDATE `creature`
   SET `position_x` = 5942.81,
       `position_y` = 1154.81,
       `position_z` = 60.7055,
       `orientation` = 5.818881
 WHERE `guid` = 4000103
   AND `id` = 990912
   AND `map` = 870
   AND ABS(`position_x` - 5980.87) < 0.01
   AND ABS(`position_y` - 1118.22) < 0.01;

UPDATE `playerbot_world_boss_caller`
   SET `rally_x` = 5942.81,
       `rally_y` = 1154.81,
       `rally_z` = 60.7055,
       `rally_o` = 5.818881
 WHERE `guid` = 4000103
   AND `boss_entry` = 69161
   AND ABS(`rally_x` - 5980.87) < 0.01
   AND ABS(`rally_y` - 1118.22) < 0.01;

COMMIT;

-- Expected result: exactly these three caller spawns and rally points at the
-- corrected coordinates. Ordos (caller guid 4000108) must remain unchanged.
SELECT `guid`, `map`, `zoneId`, `areaId`, `position_x`, `position_y`,
       `position_z`, `orientation`
  FROM `creature`
 WHERE `guid` IN (4000097, 4000102, 4000103, 4000108)
 ORDER BY `guid`;

SELECT `guid`, `boss_entry`, `boss_search_radius`, `rally_x`, `rally_y`,
       `rally_z`, `rally_o`
  FROM `playerbot_world_boss_caller`
 WHERE `guid` IN (4000097, 4000102, 4000103, 4000108)
 ORDER BY `guid`;
