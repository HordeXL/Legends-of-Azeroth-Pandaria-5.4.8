-- Exact rollback for
-- 2026_07_27_03_world_fix_wispy_vortex_raging_credit.sql.

START TRANSACTION;

SET @wispy_vortex_credit_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_wispy_vortex_credit_20260727`
);

DELETE FROM `smart_scripts`
WHERE @wispy_vortex_credit_backup_ok = 1
  AND `entryorguid` = 35386
  AND `source_type` = 0
  AND `id` = 16;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_wispy_vortex_credit_20260727` AS `backup`
WHERE @wispy_vortex_credit_backup_ok = 1;

COMMIT;
