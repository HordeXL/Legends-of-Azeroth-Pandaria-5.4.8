-- Make the Sunstrider Isle and Ammen Vale class-training quests available at
-- level 2, before their level-3 ability objectives.
--
-- Source:
--   ProjectSkyfire/SkyFire_548 commit
--   9b36efd0adca1d4814adde44ef53af61eb975e44
--
-- SkyFire's Level field maps to QuestLevel in this project's normalized
-- quest_template schema. Only the exact inherited Build-15595/18414 states
-- are accepted.

CREATE TABLE IF NOT EXISTS
    `_backup_quest_template_training_levels_20260730`
LIKE `quest_template`;

INSERT INTO `_backup_quest_template_training_levels_20260730`
SELECT `quest`.*
FROM `quest_template` AS `quest`
WHERE
    (
        (`quest`.`ID` IN
            (8328, 8329, 8563, 8564, 9392, 9393, 9676, 10068, 10069,
             10070, 10071, 10072, 10073, 26958, 26963, 26966, 26968,
             26969, 26970, 27091)
         AND `quest`.`QuestLevel` = 3
         AND `quest`.`MinLevel` = 3
         AND `quest`.`VerifiedBuild` = 15595)
        OR
        (`quest`.`ID` IN (31170, 31171, 31173)
         AND `quest`.`QuestLevel` = 3
         AND `quest`.`MinLevel` = 2
         AND `quest`.`VerifiedBuild` = 18414)
    )
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_quest_template_training_levels_20260730` AS `backup`
       WHERE `backup`.`ID` = `quest`.`ID`);

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

UPDATE `quest_template`
SET
    `QuestLevel` = 2,
    `MinLevel` = 2
WHERE @training_level_backups_ok = 1
  AND
    (
        (`ID` IN
            (8328, 8329, 8563, 8564, 9392, 9393, 9676, 10068, 10069,
             10070, 10071, 10072, 10073, 26958, 26963, 26966, 26968,
             26969, 26970, 27091)
         AND `QuestLevel` = 3
         AND `MinLevel` = 3
         AND `VerifiedBuild` = 15595)
        OR
        (`ID` IN (31170, 31171, 31173)
         AND `QuestLevel` = 3
         AND `MinLevel` = 2
         AND `VerifiedBuild` = 18414)
    );

COMMIT;
