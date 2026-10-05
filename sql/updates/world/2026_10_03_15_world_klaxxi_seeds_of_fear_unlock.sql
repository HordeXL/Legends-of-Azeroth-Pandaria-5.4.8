-- Restore the Klaxxi reputation quest chain that unlocks Seeds of Fear.
-- A Source of Terrifying Power is auto-accepted after The Klaxxi Council and
-- sends the player to Ambersmith Zikk, but the reward-chain/start relation was
-- missing. Without it, Concentrated Fear and its repeatable follow-up Seeds of
-- Fear can never become available through normal play.

UPDATE `quest_template`
SET `RewardNextQuest` = 31661
WHERE `ID` = 31006;

DELETE FROM `creature_queststarter`
WHERE `id` = 62538 AND `quest` = 31661;

INSERT INTO `creature_queststarter` (`id`, `quest`)
VALUES (62538, 31661);
