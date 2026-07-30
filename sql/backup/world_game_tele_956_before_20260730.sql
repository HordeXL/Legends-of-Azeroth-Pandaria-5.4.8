-- Exact rollback for
-- 2026_07_30_02_world_fix_stranglethornvale_teleport_height.sql.
--
-- Restores the complete game_tele row captured before the update.

START TRANSACTION;

SET @stranglethorn_tele_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_game_tele_956_20260730`
    WHERE `id` = 956
      AND `name` = 'StranglethornVale'
);

UPDATE `game_tele` AS `target`
INNER JOIN `_backup_game_tele_956_20260730` AS `backup`
    ON `backup`.`id` = `target`.`id`
SET
    `target`.`position_x` = `backup`.`position_x`,
    `target`.`position_y` = `backup`.`position_y`,
    `target`.`position_z` = `backup`.`position_z`,
    `target`.`orientation` = `backup`.`orientation`,
    `target`.`map` = `backup`.`map`,
    `target`.`name` = `backup`.`name`
WHERE @stranglethorn_tele_backup_ok = 1
  AND `target`.`id` = 956;

COMMIT;
