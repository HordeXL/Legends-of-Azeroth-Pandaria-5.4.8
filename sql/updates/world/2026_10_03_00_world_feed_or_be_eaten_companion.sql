-- Feed or Be Eaten (31092)
--
-- Kovok is a personal summon created by spell 125641.  Its existing SmartAI
-- follows the summoning player and turns Delicious Filet! (126058) into both
-- the authentic toss/grow presentation and Feeding Kovok Credit (125994).
-- The shared stationary spawn has no summoning player to store, so its credit
-- action has no target and the quest cannot advance.

DELETE FROM `creature` WHERE `guid` = 4000149 AND `id` = 62542;
