-- Exact rollback for
-- 2026_07_24_10_world_fix_drowned_thunder_lizard_tether.sql.

START TRANSACTION;

SET @drowned_thunder_lizard_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_drowned_thunder_lizard_20260724`
);

DELETE FROM `smart_scripts`
WHERE @drowned_thunder_lizard_backup_ok = 1
  AND `entryorguid` = 39464
  AND `source_type` = 0
  AND `id` = 0;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_drowned_thunder_lizard_20260724` AS `backup`
WHERE @drowned_thunder_lizard_backup_ok = 1;

COMMIT;
