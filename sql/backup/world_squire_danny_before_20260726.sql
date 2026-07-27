-- Exact rollback for
-- 2026_07_26_00_world_fix_squire_danny_valiant_credit.sql.

START TRANSACTION;

SET @squire_danny_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_squire_danny_20260726`
);

DELETE FROM `smart_scripts`
WHERE @squire_danny_backup_ok = 1
  AND `entryorguid` = 33518
  AND `source_type` = 0
  AND `id` = 3;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_squire_danny_20260726` AS `backup`
WHERE @squire_danny_backup_ok = 1;

COMMIT;
