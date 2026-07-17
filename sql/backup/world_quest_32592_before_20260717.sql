-- Exact rollback for the active world database state before restoring quest 32592.
-- Captured 2026-07-17 with Wampserver MySQL 5.7.44.
-- Pre-change state: the quest/template/addon/objective/POI rows below were absent;
-- the Wrathion starter and ender relations already existed.

START TRANSACTION;

DELETE FROM `quest_poi_points` WHERE `QuestID` = 32592;
DELETE FROM `quest_poi` WHERE `QuestID` = 32592;
DELETE FROM `quest_objective` WHERE `questId` = 32592;
DELETE FROM `quest_template_addon` WHERE `ID` = 32592;
DELETE FROM `quest_template` WHERE `ID` = 32592;

DELETE FROM `creature_queststarter` WHERE `id` = 69782 AND `quest` = 32592;
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (69782, 32592);

DELETE FROM `creature_questender` WHERE `id` = 69782 AND `quest` = 32592;
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (69782, 32592);

COMMIT;
