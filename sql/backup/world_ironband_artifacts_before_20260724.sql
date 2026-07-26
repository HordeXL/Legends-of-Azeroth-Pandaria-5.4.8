-- Exact rollback for
-- 2026_07_24_12_world_fix_ironband_artifact_credits.sql.

START TRANSACTION;

SET @ironband_artifact_backup_ok :=
(
    SELECT COUNT(*) = 3
    FROM `_backup_smart_scripts_ironband_artifacts_20260724`
);

DELETE FROM `smart_scripts`
WHERE @ironband_artifact_backup_ok = 1
  AND `entryorguid` IN (33485, 33486, 33487)
  AND `source_type` = 0
  AND `id` = 0;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_ironband_artifacts_20260724` AS `backup`
WHERE @ironband_artifact_backup_ok = 1;

COMMIT;
