-- Exact rollback for
-- 2026_07_30_06_world_restore_one_more_thing_reward_intro.sql.
--
-- Restore the complete captured row only while the active text still matches
-- the exact state installed by that migration.

START TRANSACTION;

SET @one_more_thing_reward_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`RewardText` = ' Splendid news! With the troggs taken care of, we should be able to turn our attention to Crushcog''s troublemaking. ') = 1
       AND SUM(`VerifiedBuild` = 15595) = 1
    FROM `_backup_quest_offer_reward_26329_20260730`
    WHERE `ID` = 26329
);

UPDATE `quest_offer_reward` AS `target`
INNER JOIN `_backup_quest_offer_reward_26329_20260730` AS `backup`
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
WHERE @one_more_thing_reward_backup_ok = 1
  AND `target`.`ID` = 26329
  AND `target`.`VerifiedBuild` = 15595
  AND `target`.`RewardText` = '<The high tinker reads Jessup''s report.>$B$BSplendid news! With the troggs taken care of, we should be able to turn our attention to Crushcog''s troublemaking.';

COMMIT;
