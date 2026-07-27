-- Exact rollback for
-- 2026_07_27_00_world_fix_greymist_murloc_credit.sql.

START TRANSACTION;

SET @greymist_murloc_backup_ok :=
(
    SELECT COUNT(*) = 2
    FROM `_backup_smart_scripts_greymist_murloc_credit_20260727`
);

DELETE FROM `smart_scripts`
WHERE @greymist_murloc_backup_ok = 1
  AND `entryorguid` IN (33262, 33277)
  AND `source_type` = 0
  AND `id` = 3;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_greymist_murloc_credit_20260727` AS `backup`
WHERE @greymist_murloc_backup_ok = 1;

COMMIT;
