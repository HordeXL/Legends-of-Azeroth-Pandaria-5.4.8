-- Move Sha of Anger site-2 caller to the exact point at which the player
-- Palstest safely logged out after checking the currently active pool spawn.
-- The point was tested in game and is about 60 yards from Sha.

UPDATE `creature`
   SET `position_x` = 2376.874, `position_y` = 538.020,
       `position_z` = 492.632, `orientation` = 1.6250
 WHERE `guid` = 4000098 AND `id` = 990912
   AND ABS(`position_x` - 2227.68) < 0.01
   AND ABS(`position_y` - 630.00) < 0.01;

UPDATE `playerbot_world_boss_caller`
   SET `rally_x` = 2376.874, `rally_y` = 538.020,
       `rally_z` = 492.632, `rally_o` = 1.6250
 WHERE `guid` = 4000098 AND `boss_entry` = 60491;

SELECT `guid`, `position_x`, `position_y`, `position_z`, `orientation`
  FROM `creature`
 WHERE `guid` = 4000098;

SELECT `guid`, `boss_entry`, `boss_search_radius`,
       `rally_x`, `rally_y`, `rally_z`, `rally_o`
  FROM `playerbot_world_boss_caller`
 WHERE `guid` = 4000098;
