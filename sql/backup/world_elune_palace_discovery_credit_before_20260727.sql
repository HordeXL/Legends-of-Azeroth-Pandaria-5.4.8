-- Exact rollback for
-- 2026_07_27_02_world_fix_elune_palace_discovery_credit.sql.

START TRANSACTION;

SET @elune_palace_credit_backup_ok :=
(
    SELECT COUNT(*) = 1
    FROM `_backup_smart_scripts_elune_palace_credit_20260727`
);

DELETE FROM `smart_scripts`
WHERE @elune_palace_credit_backup_ok = 1
  AND `entryorguid` = 35382
  AND `source_type` = 0
  AND `id` = 0;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_elune_palace_credit_20260727` AS `backup`
WHERE @elune_palace_credit_backup_ok = 1;

COMMIT;
