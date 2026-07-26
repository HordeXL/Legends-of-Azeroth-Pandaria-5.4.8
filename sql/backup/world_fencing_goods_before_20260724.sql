-- Exact rollback for
-- 2026_07_24_13_world_fix_fencing_goods_credit.sql.

START TRANSACTION;

SET @fencing_goods_backup_ok :=
(
    SELECT COUNT(*) = 2
    FROM `_backup_smart_scripts_fencing_goods_20260724`
);

DELETE FROM `smart_scripts`
WHERE @fencing_goods_backup_ok = 1
  AND `entryorguid` = 8719
  AND `source_type` = 0
  AND `id` = 4;

DELETE FROM `smart_scripts`
WHERE @fencing_goods_backup_ok = 1
  AND `entryorguid` = 44866
  AND `source_type` = 0
  AND `id` = 0;

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_fencing_goods_20260724` AS `backup`
WHERE @fencing_goods_backup_ok = 1;

COMMIT;
