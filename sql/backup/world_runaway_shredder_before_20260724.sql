-- Exact rollback for
-- 2026_07_24_11_world_fix_runaway_shredder_credit.sql.

START TRANSACTION;

SET @runaway_shredder_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_runaway_shredder_20260724`
);

DELETE FROM `smart_scripts`
WHERE @runaway_shredder_backup_ok = 1
  AND `entryorguid` = 35111
  AND `source_type` = 0
  AND `id` = 8;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_runaway_shredder_20260724` AS `backup`
WHERE @runaway_shredder_backup_ok = 1;

COMMIT;
