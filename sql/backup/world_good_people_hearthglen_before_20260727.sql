-- Exact rollback for
-- 2026_07_27_05_world_fix_good_people_hearthglen_credits.sql.

START TRANSACTION;

SET @good_people_hearthglen_backup_ok :=
(
    SELECT COUNT(*) = 4
    FROM `_backup_smart_scripts_good_people_hearthglen_20260727`
);

DELETE FROM `smart_scripts`
WHERE @good_people_hearthglen_backup_ok = 1
  AND `source_type` = 0
  AND `id` = 0
  AND `entryorguid` IN (45148, 45149, 45150, 45151);

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_good_people_hearthglen_20260727` AS `backup`
WHERE @good_people_hearthglen_backup_ok = 1;

COMMIT;
