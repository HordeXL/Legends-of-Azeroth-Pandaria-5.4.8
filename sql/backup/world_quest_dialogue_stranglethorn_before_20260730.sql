-- Exact rollback for
-- 2026_07_30_07_world_restore_stranglethorn_quest_dialogue.sql.
--
-- Restore complete captured rows only while all active texts still match the
-- exact states installed by the migration.

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

UPDATE `quest_offer_reward` AS `target`
INNER JOIN `_backup_quest_offer_reward_stranglethorn_20260730` AS `backup`
    ON `backup`.`ID` = `target`.`ID`
SET
    `target`.`Emote1` = `backup`.`Emote1`,
    `target`.`Emote2` = `backup`.`Emote2`,
    `target`.`Emote3` = `backup`.`Emote3`,
    `target`.`Emote4` = `backup`.`Emote4`,
    `target`.`EmoteDelay1` = `backup`.`EmoteDelay1`,
    `target`.`EmoteDelay2` = `backup`.`EmoteDelay2`,
    `target`.`EmoteDelay3` = `backup`.`EmoteDelay3`,
    `target`.`EmoteDelay4` = `backup`.`EmoteDelay4`,
    `target`.`RewardText` = `backup`.`RewardText`,
    `target`.`VerifiedBuild` = `backup`.`VerifiedBuild`
WHERE @stranglethorn_offer_backups_ok = 1
  AND
    (
        (`target`.`ID` = 26434
         AND `target`.`RewardText` = '<Flem feels the hides and smiles to himself.>$B$BExcellent work, $n!  These reagents will serve perfectly.')
        OR
        (`target`.`ID` = 26535
         AND `target`.`RewardText` = 'This is fascinating! Just think of all the applications!$B$BJust so we''re clear, I''m not thinking about using this to make an army of slaves or anything like that.  No, no... I''m much more interested in the ogre explosions!')
        OR
        (`target`.`ID` = 26816
         AND `target`.`RewardText` = 'This is fascinating! Just think of all the applications!$B$BThanks again, $n. Remember, if you ever need anything mixed for you... and I mean ANYTHING... you can always ask The Flask.')
        OR
        (`target`.`ID` = 26818
         AND `target`.`RewardText` = '<Linzi feels the hides and smiles to herself.>$B$BThese are so nice and cushy!  I think my customers are going to LOVE them!')
    );

UPDATE `quest_request_items` AS `target`
INNER JOIN `_backup_quest_request_items_26535_20260730` AS `backup`
    ON `backup`.`ID` = `target`.`ID`
SET
    `target`.`EmoteOnComplete` = `backup`.`EmoteOnComplete`,
    `target`.`EmoteOnIncomplete` = `backup`.`EmoteOnIncomplete`,
    `target`.`CompletionText` = `backup`.`CompletionText`,
    `target`.`VerifiedBuild` = `backup`.`VerifiedBuild`
WHERE @stranglethorn_request_backup_ok = 1
  AND `target`.`ID` = 26535
  AND `target`.`CompletionText` = 'Did he use shimmerweed? I''m guessing he used shimmerweed$B$BNo wait... amberseeds!  It''s gotta be amberseeds.';

COMMIT;
