-- Exact rollback for
-- 2026_07_24_06_world_fix_plague_tank_mission_credit.sql.

START TRANSACTION;

SET @plague_tank_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_plague_tank_mission_20260724`
);

DELETE FROM `smart_scripts`
WHERE @plague_tank_backup_ok = 1
  AND `entryorguid` = 24290
  AND `source_type` = 0
  AND `id` = 0;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_plague_tank_mission_20260724` AS `backup`
WHERE @plague_tank_backup_ok = 1;

COMMIT;
