-- Quest 10269 (Triangulation Point One) has complete 5.4.8 quest mechanics.
-- Remove only the inherited example override that auto-completed the quest.
-- The quest, its objectives, item, spell target, trigger and relations remain.

DELETE FROM `broken_quests`
WHERE `questId` = 10269
  AND `comment` = 'Broken quest example';
