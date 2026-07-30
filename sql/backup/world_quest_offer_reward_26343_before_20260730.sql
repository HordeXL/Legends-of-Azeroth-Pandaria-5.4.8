-- Exact rollback for
-- 2026_07_30_05_world_fix_supply_and_demand_reward_paragraph.sql.
--
-- Restore the complete captured row only while the active text still matches
-- the exact paragraph-formatted state installed by that migration.

START TRANSACTION;

SET @supply_demand_reward_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`RewardText` = 'These skins should do. Their quality isn''t too important, given that they''ll make up the inside layer of the boots, but it''s still important that they''re comfortable. If they''re a bit too rigid, I''ll use some tiger blood to soften it up. Tricks o'' the trade, you know? ') = 1
    FROM `_backup_quest_offer_reward_26343_20260730`
    WHERE `ID` = 26343
);

UPDATE `quest_offer_reward` AS `target`
INNER JOIN `_backup_quest_offer_reward_26343_20260730` AS `backup`
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
WHERE @supply_demand_reward_backup_ok = 1
  AND `target`.`ID` = 26343
  AND `target`.`RewardText` = 'These skins should do. Their quality isn''t too important, given that they''ll make up the inside layer of the boots, but it''s still important that they''re comfortable.$b$bIf they''re a bit too rigid, I''ll use some tiger blood to soften it up. Tricks o'' the trade, you know?';

COMMIT;
