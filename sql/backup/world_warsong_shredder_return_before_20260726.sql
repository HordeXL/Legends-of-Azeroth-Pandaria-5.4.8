-- Exact rollback for
-- 2026_07_26_01_world_fix_warsong_shredder_return_credit.sql.

START TRANSACTION;

SET @warsong_shredder_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_warsong_shredder_return_20260726`
);

DELETE FROM `smart_scripts`
WHERE @warsong_shredder_backup_ok = 1
  AND `entryorguid` = 33706
  AND `source_type` = 0
  AND `id` = 3;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_warsong_shredder_return_20260726` AS `backup`
WHERE @warsong_shredder_backup_ok = 1;

COMMIT;
