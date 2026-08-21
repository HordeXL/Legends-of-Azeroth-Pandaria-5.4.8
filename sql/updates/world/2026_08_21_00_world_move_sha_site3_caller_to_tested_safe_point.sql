-- Move the Sha of Anger site-3 Boss Bot Caller to the exact point saved by
-- Palstest while the site-3 boss spawn was active. The point is approximately
-- 70 yards from Sha: close enough for the configured 180-yard search radius
-- and normal player visibility without placing the caller at the boss's feet.

UPDATE `creature`
   SET `position_x` = 2700.43, `position_y` = 1770.89,
       `position_z` = 643.135, `orientation` = 5.336
 WHERE `guid` = 4000099 AND `id` = 990912
   AND ABS(`position_x` - 2877.48) < 0.01
   AND ABS(`position_y` - 1693.28) < 0.01;

UPDATE `playerbot_world_boss_caller`
   SET `rally_x` = 2700.43, `rally_y` = 1770.89,
       `rally_z` = 643.135, `rally_o` = 5.336
 WHERE `guid` = 4000099 AND `boss_entry` = 60491;

SELECT `guid`, `position_x`, `position_y`, `position_z`, `orientation`
  FROM `creature`
 WHERE `guid` = 4000099;

SELECT `guid`, `boss_entry`, `boss_search_radius`,
       `rally_x`, `rally_y`, `rally_z`, `rally_o`
  FROM `playerbot_world_boss_caller`
 WHERE `guid` = 4000099;
