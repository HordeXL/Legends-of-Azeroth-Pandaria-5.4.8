-- Exact rollback for
-- 2026_07_24_08_world_fix_alliance_camp_burning_credit.sql.

START TRANSACTION;

SET @alliance_camp_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_alliance_camp_20260724`
);

DELETE FROM `smart_scripts`
WHERE @alliance_camp_backup_ok = 1
  AND `entryorguid` = 56509
  AND `source_type` = 0
  AND `id` = 0;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_alliance_camp_20260724` AS `backup`
WHERE @alliance_camp_backup_ok = 1;

COMMIT;
