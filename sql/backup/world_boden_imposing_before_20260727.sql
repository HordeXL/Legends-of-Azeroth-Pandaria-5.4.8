-- Exact rollback for
-- 2026_07_27_06_world_fix_boden_imposing_credit.sql.

START TRANSACTION;

SET @boden_imposing_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_boden_imposing_20260727`
);

DELETE FROM `smart_scripts`
WHERE @boden_imposing_backup_ok = 1
  AND `entryorguid` = 42471
  AND `source_type` = 0
  AND `id` = 0;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_boden_imposing_20260727` AS `backup`
WHERE @boden_imposing_backup_ok = 1;

COMMIT;
