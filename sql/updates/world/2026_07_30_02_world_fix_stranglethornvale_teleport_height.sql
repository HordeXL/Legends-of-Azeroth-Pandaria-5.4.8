-- Fix .tele StranglethornVale placing the character below the terrain.
--
-- Source: ProjectSkyfire/SkyFire_548 commit
-- f8317367afd79c0b6b11f7b2febb287faf3827ee
-- ("Fix characters falling from map when teleporting to stranglethorn vale").
--
-- The update is deliberately guarded by the complete known 5.4.8 row.
-- No row is inserted or deleted.

CREATE TABLE IF NOT EXISTS `_backup_game_tele_956_20260730`
LIKE `game_tele`;

INSERT INTO `_backup_game_tele_956_20260730`
SELECT `tele`.*
FROM `game_tele` AS `tele`
WHERE `tele`.`id` = 956
  AND ABS(`tele`.`position_x` - (-12644.3)) < 0.01
  AND ABS(`tele`.`position_y` - (-377.411)) < 0.01
  AND ABS(`tele`.`position_z` - 10.1021) < 0.001
  AND ABS(`tele`.`orientation` - 6.09978) < 0.0001
  AND `tele`.`map` = 0
  AND `tele`.`name` = 'StranglethornVale'
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_game_tele_956_20260730` AS `backup`
       WHERE `backup`.`id` = `tele`.`id`);

SET @stranglethorn_tele_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(ABS(`position_x` - (-12644.3)) < 0.01
               AND ABS(`position_y` - (-377.411)) < 0.01
               AND ABS(`position_z` - 10.1021) < 0.001
               AND ABS(`orientation` - 6.09978) < 0.0001
               AND `map` = 0
               AND `name` = 'StranglethornVale') = 1
    FROM `_backup_game_tele_956_20260730`
    WHERE `id` = 956
);

UPDATE `game_tele`
SET `position_z` = 18.2021
WHERE @stranglethorn_tele_backup_ok = 1
  AND `id` = 956
  AND ABS(`position_x` - (-12644.3)) < 0.01
  AND ABS(`position_y` - (-377.411)) < 0.01
  AND ABS(`position_z` - 10.1021) < 0.001
  AND ABS(`orientation` - 6.09978) < 0.0001
  AND `map` = 0
  AND `name` = 'StranglethornVale';
