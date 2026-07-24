-- Exact rollback for
-- 2026_07_24_03_world_remove_instructor_mylva_automatic_mental_credit.sql.

START TRANSACTION;

SET @mylva_mental_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_mylva_mental_credit_20260724`
);

DELETE FROM `smart_scripts`
WHERE @mylva_mental_backup_ok = 1
  AND `entryorguid` = 39413
  AND `source_type` = 0
  AND `id` = 1;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_mylva_mental_credit_20260724` AS `backup`
WHERE @mylva_mental_backup_ok = 1;

COMMIT;
