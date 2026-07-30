-- Exact rollback for
-- 2026_07_30_08_world_fix_starting_training_quest_levels.sql.
--
-- Restore only the two fields changed by the migration, using the complete
-- captured quest_template rows, and only while the active rows still match
-- the installed level-2 state.

START TRANSACTION;

SET @training_level_backups_ok :=
(
    SELECT COUNT(*) = 23
       AND SUM(`QuestLevel` = 3) = 23
       AND SUM(`MinLevel` = 3) = 20
       AND SUM(`MinLevel` = 2) = 3
       AND SUM(`VerifiedBuild` = 15595) = 20
       AND SUM(`VerifiedBuild` = 18414) = 3
    FROM `_backup_quest_template_training_levels_20260730`
    WHERE `ID` IN
        (8328, 8329, 8563, 8564, 9392, 9393, 9676, 10068, 10069, 10070,
         10071, 10072, 10073, 26958, 26963, 26966, 26968, 26969, 26970,
         27091, 31170, 31171, 31173)
);

UPDATE `quest_template` AS `target`
INNER JOIN `_backup_quest_template_training_levels_20260730` AS `backup`
    ON `backup`.`ID` = `target`.`ID`
SET
    `target`.`QuestLevel` = `backup`.`QuestLevel`,
    `target`.`MinLevel` = `backup`.`MinLevel`
WHERE @training_level_backups_ok = 1
  AND `target`.`QuestLevel` = 2
  AND `target`.`MinLevel` = 2
  AND `target`.`VerifiedBuild` = `backup`.`VerifiedBuild`;

COMMIT;
