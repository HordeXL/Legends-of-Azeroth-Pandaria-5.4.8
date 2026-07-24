-- Exact rollback for
-- 2026_07_24_05_world_fix_orchard_fire_spitfire_credit.sql.

START TRANSACTION;

SET @orchard_fire_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_orchard_fire_spitfire_20260724`
);

DELETE FROM `smart_scripts`
WHERE @orchard_fire_backup_ok = 1
  AND `entryorguid` = 54780
  AND `source_type` = 0
  AND `id` = 0;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_orchard_fire_spitfire_20260724` AS `backup`
WHERE @orchard_fire_backup_ok = 1;

COMMIT;
