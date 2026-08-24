-- Backup of the exact broken_quests override removed by
-- 2026_08_22_04_world_remove_broken_quest_example_10269.sql.
--
-- Quest 10269 (Triangulation Point One) is valid for build 5.4.8 and has its
-- normal quest template, supplied item 28962, spell target 34830, trigger
-- creature 20086 and area trigger relation 4473.  This row caused the core to
-- complete the quest immediately instead of requiring those mechanics.

DELETE FROM `broken_quests`
WHERE `questId` = 10269
  AND `comment` = 'Broken quest example';

INSERT INTO `broken_quests` (`questId`, `comment`) VALUES
(10269, 'Broken quest example');
