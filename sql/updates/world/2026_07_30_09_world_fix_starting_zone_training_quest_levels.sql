-- Make class-training quests in five additional starting zones available at
-- level 2, before their level-3 ability objectives.
--
-- Sources:
--   ProjectSkyfire/SkyFire_548 commits
--   5a2b05562cd518fd68afdb93068b53417c6c0c9c
--   53420dffd5b614515b881e59d5b47a618bc810db
--   668958d128a5cd057ae06ee82f618ce21a7fa3b3
--   46a522bcd7f35ecd82ccce021e822ad8efe70f08
--   12a820e457fdf8399110c0d7ee041e424556263e
--
-- SkyFire's Level field maps to QuestLevel in this project's normalized
-- quest_template schema. This migration deliberately does not import the
-- commits' text, class/race, chain, or spawn changes.

CREATE TABLE IF NOT EXISTS
    `_backup_quest_template_starting_zone_levels_20260730`
LIKE `quest_template`;

INSERT INTO `_backup_quest_template_starting_zone_levels_20260730`
SELECT `quest`.*
FROM `quest_template` AS `quest`
WHERE `quest`.`ID` IN
    (2383, 3087, 3088, 3089, 3090, 3091, 3092, 3093, 3094, 3100, 3101,
     3102, 3103, 3104, 3105, 3106, 3107, 3108, 3109, 3110, 3115, 3117,
     3118, 3119, 3120, 24494, 24496, 24526, 24527, 24528, 24530, 24531,
     24532, 24533, 25138, 25139, 25141, 25143, 25145, 25147, 25149, 26841,
     26904, 26910, 26913, 26914, 26915, 26916, 26917, 26918, 26919, 26940,
     26945, 26946, 26947, 26948, 26949, 27014, 27015, 27020, 27021, 27023,
     27027, 27066, 27067, 31141, 31142, 31150, 31151, 31156, 31157, 31165,
     31166, 31168, 31169)
  AND `quest`.`QuestLevel` = 3
  AND
    (
        (`quest`.`MinLevel` = 3 AND `quest`.`VerifiedBuild` = 15595)
        OR
        (`quest`.`MinLevel` = 2 AND `quest`.`VerifiedBuild` = 18414)
    )
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_quest_template_starting_zone_levels_20260730` AS `backup`
       WHERE `backup`.`ID` = `quest`.`ID`);

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

UPDATE `quest_template`
SET
    `QuestLevel` = 2,
    `MinLevel` = 2
WHERE @starting_zone_level_backups_ok = 1
  AND `ID` IN
    (2383, 3087, 3088, 3089, 3090, 3091, 3092, 3093, 3094, 3100, 3101,
     3102, 3103, 3104, 3105, 3106, 3107, 3108, 3109, 3110, 3115, 3117,
     3118, 3119, 3120, 24494, 24496, 24526, 24527, 24528, 24530, 24531,
     24532, 24533, 25138, 25139, 25141, 25143, 25145, 25147, 25149, 26841,
     26904, 26910, 26913, 26914, 26915, 26916, 26917, 26918, 26919, 26940,
     26945, 26946, 26947, 26948, 26949, 27014, 27015, 27020, 27021, 27023,
     27027, 27066, 27067, 31141, 31142, 31150, 31151, 31156, 31157, 31165,
     31166, 31168, 31169)
  AND `QuestLevel` = 3
  AND
    (
        (`MinLevel` = 3 AND `VerifiedBuild` = 15595)
        OR
        (`MinLevel` = 2 AND `VerifiedBuild` = 18414)
    );

COMMIT;
