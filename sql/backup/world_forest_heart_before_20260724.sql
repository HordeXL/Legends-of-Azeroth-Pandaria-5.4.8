-- Exact rollback for
-- 2026_07_24_09_world_fix_forest_heart_credit.sql.

START TRANSACTION;

SET @forest_heart_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_forest_heart_20260724`
);

DELETE FROM `smart_scripts`
WHERE @forest_heart_backup_ok = 1
  AND `entryorguid` = 33847
  AND `source_type` = 0
  AND `id` = 0;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_forest_heart_20260724` AS `backup`
WHERE @forest_heart_backup_ok = 1;

COMMIT;
