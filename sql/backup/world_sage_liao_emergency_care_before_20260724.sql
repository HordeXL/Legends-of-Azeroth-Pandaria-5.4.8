-- Exact rollback for
-- 2026_07_24_04_world_fix_sage_liao_emergency_care_credit.sql.

START TRANSACTION;

SET @sage_liao_backup_ok :=
(
    SELECT COUNT(*) = 2
    FROM `_backup_smart_scripts_sage_liao_emergency_care_20260724`
);

DELETE FROM `smart_scripts`
WHERE @sage_liao_backup_ok = 1
  AND `entryorguid` IN (60694, 60785)
  AND `source_type` = 0
  AND `id` = 0;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_sage_liao_emergency_care_20260724` AS `backup`
WHERE @sage_liao_backup_ok = 1;

COMMIT;
