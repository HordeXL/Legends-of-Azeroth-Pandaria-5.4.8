-- Exact rollback for
-- 2026_07_27_04_world_fix_ten_dedicated_quest_credit_spells.sql.

START TRANSACTION;

SET @ten_quest_credit_backup_ok :=
(
    SELECT COUNT(*) = 10
    FROM `_backup_smart_scripts_ten_quest_credits_20260727`
);

DELETE FROM `smart_scripts`
WHERE @ten_quest_credit_backup_ok = 1
  AND `source_type` = 0
  AND
  (
       (`entryorguid` = 35595 AND `id` = 0)
    OR (`entryorguid` = 36079 AND `id` = 1)
    OR (`entryorguid` = 36297 AND `id` IN (2, 4))
    OR (`entryorguid` = 36509 AND `id` = 1)
    OR (`entryorguid` IN (39730, 39736, 39737, 39738, 39933) AND `id` = 0)
  );

INSERT INTO `smart_scripts`
SELECT `backup`.*
FROM `_backup_smart_scripts_ten_quest_credits_20260727` AS `backup`
WHERE @ten_quest_credit_backup_ok = 1;

COMMIT;
