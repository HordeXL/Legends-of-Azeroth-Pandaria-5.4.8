-- Restore the missing introductory emote in the reward dialogue for quest
-- 26329, One More Thing.
--
-- Source:
--   ProjectSkyfire/SkyFire_548 commit
--   ea381e76790d0163eb20d9376fd67548468fbcba
--
-- The source's combined quest_template OfferRewardText is adapted to this
-- project's normalized quest_offer_reward table. The migration only accepts
-- the exact incomplete Build-15595 row currently inherited from the base.

CREATE TABLE IF NOT EXISTS `_backup_quest_offer_reward_26329_20260730`
LIKE `quest_offer_reward`;

INSERT INTO `_backup_quest_offer_reward_26329_20260730`
SELECT `reward`.*
FROM `quest_offer_reward` AS `reward`
WHERE `reward`.`ID` = 26329
  AND `reward`.`RewardText` = ' Splendid news! With the troggs taken care of, we should be able to turn our attention to Crushcog''s troublemaking. '
  AND `reward`.`VerifiedBuild` = 15595
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_quest_offer_reward_26329_20260730` AS `backup`
       WHERE `backup`.`ID` = `reward`.`ID`);

START TRANSACTION;

SET @one_more_thing_reward_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`RewardText` = ' Splendid news! With the troggs taken care of, we should be able to turn our attention to Crushcog''s troublemaking. ') = 1
       AND SUM(`VerifiedBuild` = 15595) = 1
    FROM `_backup_quest_offer_reward_26329_20260730`
    WHERE `ID` = 26329
);

SET @one_more_thing_reward_dependencies_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`LogTitle` = 'One More Thing') = 1
       AND SUM(`VerifiedBuild` = 15595) = 1
    FROM `quest_template`
    WHERE `ID` = 26329
);

UPDATE `quest_offer_reward`
SET `RewardText` = '<The high tinker reads Jessup''s report.>$B$BSplendid news! With the troggs taken care of, we should be able to turn our attention to Crushcog''s troublemaking.'
WHERE @one_more_thing_reward_backup_ok = 1
  AND @one_more_thing_reward_dependencies_ok = 1
  AND `ID` = 26329
  AND `VerifiedBuild` = 15595
  AND `RewardText` = ' Splendid news! With the troggs taken care of, we should be able to turn our attention to Crushcog''s troublemaking. ';

COMMIT;
