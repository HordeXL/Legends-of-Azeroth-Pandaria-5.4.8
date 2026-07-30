-- Restore the missing paragraph break in the Supply and Demand reward text.
--
-- Sources:
--   ProjectSkyfire/SkyFire_548 commit
--   27e76cd6a5d3518638eb5847e8c351a2fc25fcb3
--   SFDB full 548 release 25.001
--
-- The upstream combined quest_template text is adapted to this project's
-- normalized quest_offer_reward table and its client `$b` line-break syntax.

CREATE TABLE IF NOT EXISTS `_backup_quest_offer_reward_26343_20260730`
LIKE `quest_offer_reward`;

INSERT INTO `_backup_quest_offer_reward_26343_20260730`
SELECT `reward`.*
FROM `quest_offer_reward` AS `reward`
WHERE `reward`.`ID` = 26343
  AND `reward`.`RewardText` = 'These skins should do. Their quality isn''t too important, given that they''ll make up the inside layer of the boots, but it''s still important that they''re comfortable. If they''re a bit too rigid, I''ll use some tiger blood to soften it up. Tricks o'' the trade, you know? '
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_quest_offer_reward_26343_20260730` AS `backup`
       WHERE `backup`.`ID` = `reward`.`ID`);

START TRANSACTION;

SET @supply_demand_reward_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`RewardText` = 'These skins should do. Their quality isn''t too important, given that they''ll make up the inside layer of the boots, but it''s still important that they''re comfortable. If they''re a bit too rigid, I''ll use some tiger blood to soften it up. Tricks o'' the trade, you know? ') = 1
    FROM `_backup_quest_offer_reward_26343_20260730`
    WHERE `ID` = 26343
);

SET @supply_demand_reward_dependencies_ok :=
(
    SELECT
        (SELECT COUNT(*)
         FROM `quest_template`
         WHERE `ID` = 26343
           AND `LogTitle` = 'Supply and Demand'
           AND `VerifiedBuild` = 15595) = 1
        AND
        (SELECT COUNT(*)
         FROM `quest_objective`
         WHERE `questId` = 26343
           AND `type` = 1
           AND `objectId` = 4053
           AND `amount` = 2) = 1
);

UPDATE `quest_offer_reward`
SET `RewardText` = 'These skins should do. Their quality isn''t too important, given that they''ll make up the inside layer of the boots, but it''s still important that they''re comfortable.$b$bIf they''re a bit too rigid, I''ll use some tiger blood to soften it up. Tricks o'' the trade, you know?'
WHERE @supply_demand_reward_backup_ok = 1
  AND @supply_demand_reward_dependencies_ok = 1
  AND `ID` = 26343
  AND `RewardText` = 'These skins should do. Their quality isn''t too important, given that they''ll make up the inside layer of the boots, but it''s still important that they''re comfortable. If they''re a bit too rigid, I''ll use some tiger blood to soften it up. Tricks o'' the trade, you know? ';

COMMIT;
