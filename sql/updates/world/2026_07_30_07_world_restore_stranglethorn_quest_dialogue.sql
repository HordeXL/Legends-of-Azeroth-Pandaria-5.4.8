-- Restore missing emotes and paragraph breaks in four Stranglethorn quest
-- dialogues.
--
-- Sources:
--   ProjectSkyfire/SkyFire_548 commits
--   6cd96227f27c8fb79ba6b3c2529afabe981ef2e3
--   b6eb93218b4736be823510197afc380c88c2cbe8
--
-- The source's combined quest_template fields are adapted to this project's
-- normalized quest_offer_reward and quest_request_items tables. Only the
-- exact incomplete Build-15595 rows inherited from the base are accepted.

CREATE TABLE IF NOT EXISTS
    `_backup_quest_offer_reward_stranglethorn_20260730`
LIKE `quest_offer_reward`;

CREATE TABLE IF NOT EXISTS
    `_backup_quest_request_items_26535_20260730`
LIKE `quest_request_items`;

INSERT INTO `_backup_quest_offer_reward_stranglethorn_20260730`
SELECT `reward`.*
FROM `quest_offer_reward` AS `reward`
WHERE
    (
        (`reward`.`ID` = 26434
         AND `reward`.`RewardText` = ' Excellent work, $n!  These reagents will serve perfectly. ')
        OR
        (`reward`.`ID` = 26535
         AND `reward`.`RewardText` = 'This is fascinating!  Just think of all the applications! Just so we''re clear, I''m not thinking about using this to make an army of slaves or anything like that.  No, no... I''m much more interested in the ogre explosions! ')
        OR
        (`reward`.`ID` = 26816
         AND `reward`.`RewardText` = 'This is fascinating!  Just think of all the applications! Thanks again, $n.  Remember, if you ever need anything mixed for you... and I mean ANYTHING... you can always ask The Flask. ')
        OR
        (`reward`.`ID` = 26818
         AND `reward`.`RewardText` = ' These are so nice and cushy!  I think my customers are going to LOVE them! ')
    )
  AND `reward`.`VerifiedBuild` = 15595
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_quest_offer_reward_stranglethorn_20260730` AS `backup`
       WHERE `backup`.`ID` = `reward`.`ID`);

INSERT INTO `_backup_quest_request_items_26535_20260730`
SELECT `request`.*
FROM `quest_request_items` AS `request`
WHERE `request`.`ID` = 26535
  AND `request`.`CompletionText` = 'Did he use shimmerweed?  I''m guessing he used shimmerweed. No wait... amberseeds!  It''s gotta be amberseeds. '
  AND `request`.`VerifiedBuild` = 15595
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_quest_request_items_26535_20260730` AS `backup`
       WHERE `backup`.`ID` = `request`.`ID`);

START TRANSACTION;

SET @stranglethorn_offer_backups_ok :=
(
    SELECT
        (SELECT COUNT(*)
         FROM `_backup_quest_offer_reward_stranglethorn_20260730`
         WHERE `ID` = 26434
           AND `RewardText` = ' Excellent work, $n!  These reagents will serve perfectly. '
           AND `VerifiedBuild` = 15595) = 1
        AND
        (SELECT COUNT(*)
         FROM `_backup_quest_offer_reward_stranglethorn_20260730`
         WHERE `ID` = 26535
           AND `RewardText` = 'This is fascinating!  Just think of all the applications! Just so we''re clear, I''m not thinking about using this to make an army of slaves or anything like that.  No, no... I''m much more interested in the ogre explosions! '
           AND `VerifiedBuild` = 15595) = 1
        AND
        (SELECT COUNT(*)
         FROM `_backup_quest_offer_reward_stranglethorn_20260730`
         WHERE `ID` = 26816
           AND `RewardText` = 'This is fascinating!  Just think of all the applications! Thanks again, $n.  Remember, if you ever need anything mixed for you... and I mean ANYTHING... you can always ask The Flask. '
           AND `VerifiedBuild` = 15595) = 1
        AND
        (SELECT COUNT(*)
         FROM `_backup_quest_offer_reward_stranglethorn_20260730`
         WHERE `ID` = 26818
           AND `RewardText` = ' These are so nice and cushy!  I think my customers are going to LOVE them! '
           AND `VerifiedBuild` = 15595) = 1
);

SET @stranglethorn_request_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`CompletionText` = 'Did he use shimmerweed?  I''m guessing he used shimmerweed. No wait... amberseeds!  It''s gotta be amberseeds. ') = 1
       AND SUM(`VerifiedBuild` = 15595) = 1
    FROM `_backup_quest_request_items_26535_20260730`
    WHERE `ID` = 26535
);

SET @stranglethorn_dialogue_dependencies_ok :=
(
    SELECT
        (SELECT COUNT(*) FROM `quest_template`
         WHERE `ID` = 26434 AND `LogTitle` = 'Primal Reagents of Power'
           AND `VerifiedBuild` = 15595) = 1
        AND
        (SELECT COUNT(*) FROM `quest_template`
         WHERE `ID` = 26535 AND `LogTitle` = 'Recipe for Disaster'
           AND `VerifiedBuild` = 15595) = 1
        AND
        (SELECT COUNT(*) FROM `quest_template`
         WHERE `ID` = 26816 AND `LogTitle` = 'Recipe for Disaster'
           AND `VerifiedBuild` = 15595) = 1
        AND
        (SELECT COUNT(*) FROM `quest_template`
         WHERE `ID` = 26818 AND `LogTitle` = 'Plush Pelts'
           AND `VerifiedBuild` = 15595) = 1
        AND
        (SELECT COUNT(*) FROM `quest_objective`
         WHERE `questId` = 26434 AND `type` = 1
           AND `objectId` = 58812 AND `amount` = 4) = 1
        AND
        (SELECT COUNT(*) FROM `quest_objective`
         WHERE `questId` = 26434 AND `type` = 1
           AND `objectId` = 58813 AND `amount` = 4) = 1
        AND
        (SELECT COUNT(*) FROM `quest_objective`
         WHERE `questId` = 26535 AND `type` = 1
           AND `objectId` = 58901 AND `amount` = 1) = 1
        AND
        (SELECT COUNT(*) FROM `quest_objective`
         WHERE `questId` = 26816 AND `type` = 1
           AND `objectId` = 58901 AND `amount` = 1) = 1
        AND
        (SELECT COUNT(*) FROM `quest_objective`
         WHERE `questId` = 26818 AND `type` = 1
           AND `objectId` = 58812 AND `amount` = 4) = 1
        AND
        (SELECT COUNT(*) FROM `quest_objective`
         WHERE `questId` = 26818 AND `type` = 1
           AND `objectId` = 58813 AND `amount` = 4) = 1
);

UPDATE `quest_offer_reward`
SET `RewardText` = '<Flem feels the hides and smiles to himself.>$B$BExcellent work, $n!  These reagents will serve perfectly.'
WHERE @stranglethorn_offer_backups_ok = 1
  AND @stranglethorn_dialogue_dependencies_ok = 1
  AND `ID` = 26434
  AND `VerifiedBuild` = 15595
  AND `RewardText` = ' Excellent work, $n!  These reagents will serve perfectly. ';

UPDATE `quest_offer_reward`
SET `RewardText` = 'This is fascinating! Just think of all the applications!$B$BJust so we''re clear, I''m not thinking about using this to make an army of slaves or anything like that.  No, no... I''m much more interested in the ogre explosions!'
WHERE @stranglethorn_offer_backups_ok = 1
  AND @stranglethorn_dialogue_dependencies_ok = 1
  AND `ID` = 26535
  AND `VerifiedBuild` = 15595
  AND `RewardText` = 'This is fascinating!  Just think of all the applications! Just so we''re clear, I''m not thinking about using this to make an army of slaves or anything like that.  No, no... I''m much more interested in the ogre explosions! ';

UPDATE `quest_offer_reward`
SET `RewardText` = 'This is fascinating! Just think of all the applications!$B$BThanks again, $n. Remember, if you ever need anything mixed for you... and I mean ANYTHING... you can always ask The Flask.'
WHERE @stranglethorn_offer_backups_ok = 1
  AND @stranglethorn_dialogue_dependencies_ok = 1
  AND `ID` = 26816
  AND `VerifiedBuild` = 15595
  AND `RewardText` = 'This is fascinating!  Just think of all the applications! Thanks again, $n.  Remember, if you ever need anything mixed for you... and I mean ANYTHING... you can always ask The Flask. ';

UPDATE `quest_offer_reward`
SET `RewardText` = '<Linzi feels the hides and smiles to herself.>$B$BThese are so nice and cushy!  I think my customers are going to LOVE them!'
WHERE @stranglethorn_offer_backups_ok = 1
  AND @stranglethorn_dialogue_dependencies_ok = 1
  AND `ID` = 26818
  AND `VerifiedBuild` = 15595
  AND `RewardText` = ' These are so nice and cushy!  I think my customers are going to LOVE them! ';

UPDATE `quest_request_items`
SET `CompletionText` = 'Did he use shimmerweed? I''m guessing he used shimmerweed$B$BNo wait... amberseeds!  It''s gotta be amberseeds.'
WHERE @stranglethorn_request_backup_ok = 1
  AND @stranglethorn_dialogue_dependencies_ok = 1
  AND `ID` = 26535
  AND `VerifiedBuild` = 15595
  AND `CompletionText` = 'Did he use shimmerweed?  I''m guessing he used shimmerweed. No wait... amberseeds!  It''s gotta be amberseeds. ';

COMMIT;
