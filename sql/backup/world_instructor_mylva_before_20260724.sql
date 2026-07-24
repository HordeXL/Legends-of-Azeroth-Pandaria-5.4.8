-- Exact rollback for
-- 2026_07_24_02_world_fix_instructor_mylva_training_spell_chain.sql.

START TRANSACTION;

SET @mylva_backup_ok :=
(
    SELECT COUNT(*) = 4
    FROM `_backup_smart_scripts_instructor_mylva_20260724`
);

DELETE FROM `smart_scripts`
WHERE @mylva_backup_ok = 1
  AND `entryorguid` = 3941300
  AND `source_type` = 9
  AND `id` BETWEEN 0 AND 3;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_instructor_mylva_20260724` AS `backup`
WHERE @mylva_backup_ok = 1;

COMMIT;
