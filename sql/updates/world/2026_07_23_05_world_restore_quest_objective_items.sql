-- Restore seven genuine 5.4.8 quest-item templates referenced by
-- quest_objective but missing from item_template.
--
-- Exact numeric rows were recovered from the local 5.4.8 Build 18414 source:
-- C:/wamp64/www/pandaria_5.4.8/sql/base/2024_08_01_world.sql
-- Client Item.db2 Build 18273 also contains all seven item IDs.
-- English names are confirmed by the active Build 18414 quest text.
--
-- All seven source rows have identical values except entry, name and displayid.
-- Keep one exact source row in a temporary table, then clone it while changing
-- only those three fields. INSERT IGNORE preserves any pre-existing live row.

DROP TEMPORARY TABLE IF EXISTS `_tmp_item_template_quest_objective_20260723`;
CREATE TEMPORARY TABLE `_tmp_item_template_quest_objective_20260723`
LIKE `item_template`;

INSERT INTO `_tmp_item_template_quest_objective_20260723` VALUES
(68674,12,1,-1,'Steelback''s Claw',94786,2,0,8192,0,1.0004,1,1,0,0,0,-1,-1,1,79,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,0,-1,0,0,0,-1,0,-1,0,0,0,-1,0,-1,0,0,0,-1,0,-1,0,0,0,-1,0,-1,2,'',0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,18414);

INSERT IGNORE INTO `item_template`
SELECT * FROM `_tmp_item_template_quest_objective_20260723`;

UPDATE `_tmp_item_template_quest_objective_20260723`
SET `entry` = 68676, `name` = 'Grumpfin''s Eye', `displayid` = 79013;
INSERT IGNORE INTO `item_template`
SELECT * FROM `_tmp_item_template_quest_objective_20260723`;

UPDATE `_tmp_item_template_quest_objective_20260723`
SET `entry` = 68680, `name` = 'Coconut', `displayid` = 55088;
INSERT IGNORE INTO `item_template`
SELECT * FROM `_tmp_item_template_quest_objective_20260723`;

UPDATE `_tmp_item_template_quest_objective_20260723`
SET `entry` = 71961, `name` = 'Plump Frog', `displayid` = 6270;
INSERT IGNORE INTO `item_template`
SELECT * FROM `_tmp_item_template_quest_objective_20260723`;

UPDATE `_tmp_item_template_quest_objective_20260723`
SET `entry` = 73366, `name` = 'Waterlogged Scrap', `displayid` = 101837;
INSERT IGNORE INTO `item_template`
SELECT * FROM `_tmp_item_template_quest_objective_20260723`;

UPDATE `_tmp_item_template_quest_objective_20260723`
SET `entry` = 93396, `name` = 'Plundered Proffering', `displayid` = 9854;
INSERT IGNORE INTO `item_template`
SELECT * FROM `_tmp_item_template_quest_objective_20260723`;

UPDATE `_tmp_item_template_quest_objective_20260723`
SET `entry` = 93660, `name` = 'Thunder-Laced Egg', `displayid` = 119883;
INSERT IGNORE INTO `item_template`
SELECT * FROM `_tmp_item_template_quest_objective_20260723`;

DROP TEMPORARY TABLE `_tmp_item_template_quest_objective_20260723`;
