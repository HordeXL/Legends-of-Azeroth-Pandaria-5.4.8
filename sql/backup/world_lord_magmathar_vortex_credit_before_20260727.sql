-- Exact rollback for
-- 2026_07_27_01_world_fix_lord_magmathar_vortex_credit.sql.

START TRANSACTION;

SET @lord_magmathar_vortex_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_lord_magmathar_vortex_credit_20260727`
);

DELETE FROM `smart_scripts`
WHERE @lord_magmathar_vortex_backup_ok = 1
  AND `entryorguid` = 34322
  AND `source_type` = 0
  AND `id` = 7;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_lord_magmathar_vortex_credit_20260727` AS `backup`
WHERE @lord_magmathar_vortex_backup_ok = 1;

COMMIT;
