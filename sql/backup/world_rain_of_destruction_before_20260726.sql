-- Exact rollback for
-- 2026_07_26_02_world_fix_rain_of_destruction_credits.sql.

START TRANSACTION;

SET @rain_of_destruction_backup_ok :=
(
    SELECT COUNT(*) = 2
    FROM `_backup_smart_scripts_rain_of_destruction_20260726`
);

DELETE FROM `smart_scripts`
WHERE @rain_of_destruction_backup_ok = 1
  AND `entryorguid` = 33965
  AND `source_type` = 0
  AND `id` IN (8, 9);

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_rain_of_destruction_20260726` AS `backup`
WHERE @rain_of_destruction_backup_ok = 1;

COMMIT;
