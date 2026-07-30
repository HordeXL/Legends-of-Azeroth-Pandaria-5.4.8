-- Exact rollback for
-- 2026_07_30_09_world_fix_starting_zone_training_quest_levels.sql.
--
-- Restore only the two fields changed by the migration, using the complete
-- captured quest_template rows, and only while the active rows still match
-- the installed level-2 state.

START TRANSACTION;

SET @starting_zone_level_backups_ok :=
(
    SELECT COUNT(*) = 75
       AND SUM(`QuestLevel` = 3) = 75
       AND SUM(`MinLevel` = 3) = 65
       AND SUM(`MinLevel` = 2) = 10
       AND SUM(`VerifiedBuild` = 15595) = 65
       AND SUM(`VerifiedBuild` = 18414) = 10
       AND SUM(`LogTitle` <> '') = 75
    FROM `_backup_quest_template_starting_zone_levels_20260730`
    WHERE `ID` IN
        (2383, 3087, 3088, 3089, 3090, 3091, 3092, 3093, 3094, 3100,
         3101, 3102, 3103, 3104, 3105, 3106, 3107, 3108, 3109, 3110,
         3115, 3117, 3118, 3119, 3120, 24494, 24496, 24526, 24527, 24528,
         24530, 24531, 24532, 24533, 25138, 25139, 25141, 25143, 25145,
         25147, 25149, 26841, 26904, 26910, 26913, 26914, 26915, 26916,
         26917, 26918, 26919, 26940, 26945, 26946, 26947, 26948, 26949,
         27014, 27015, 27020, 27021, 27023, 27027, 27066, 27067, 31141,
         31142, 31150, 31151, 31156, 31157, 31165, 31166, 31168, 31169)
);

UPDATE `quest_template` AS `target`
INNER JOIN `_backup_quest_template_starting_zone_levels_20260730` AS `backup`
    ON `backup`.`ID` = `target`.`ID`
SET
    `target`.`QuestLevel` = `backup`.`QuestLevel`,
    `target`.`MinLevel` = `backup`.`MinLevel`
WHERE @starting_zone_level_backups_ok = 1
  AND `target`.`QuestLevel` = 2
  AND `target`.`MinLevel` = 2
  AND `target`.`VerifiedBuild` = `backup`.`VerifiedBuild`;

COMMIT;
