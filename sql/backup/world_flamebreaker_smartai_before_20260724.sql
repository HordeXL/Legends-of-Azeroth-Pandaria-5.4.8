-- Exact rollback for
-- 2026_07_24_01_world_remove_duplicate_flamebreaker_summons.sql.

START TRANSACTION;

SET @flamebreaker_backup_ok :=
(
    SELECT COUNT(*) = 7
    FROM `_backup_smart_scripts_flamebreaker_20260724`
);

DELETE FROM `smart_scripts`
WHERE @flamebreaker_backup_ok = 1
  AND `entryorguid` = 38896
  AND `source_type` = 0
  AND `id` BETWEEN 0 AND 6;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_flamebreaker_20260724` AS `backup`
WHERE @flamebreaker_backup_ok = 1;

COMMIT;
