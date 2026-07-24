-- Exact rollback for
-- 2026_07_24_07_world_fix_ol_blasty_credit.sql.

START TRANSACTION;

SET @ol_blasty_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_ol_blasty_20260724`
);

DELETE FROM `smart_scripts`
WHERE @ol_blasty_backup_ok = 1
  AND `entryorguid` = 43560
  AND `source_type` = 0
  AND `id` = 0;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_ol_blasty_20260724` AS `backup`
WHERE @ol_blasty_backup_ok = 1;

COMMIT;
