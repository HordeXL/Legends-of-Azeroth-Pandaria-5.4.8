-- ============================================================
-- 2026_09_30_09_world_isle_of_thunder_gaps.sql
-- 雷神岛(Isle of Thunder, WorldMapAreaId 928)任务链修复
--
-- 发现(2026-09-30 审计):
-- 1. "Forge Ahead!"(32292 部落 / 32587 联盟)的唯一发放/交付 NPC
--    70551 Scout Captain Elsia / 70552 Scout Captain Daelin 均无刷怪,
--    而 67985(Elsia 部落日常位) 与 67998(Daelin 联盟日常位) 在
--    map 1064 已刷出(guid 566605/567018/567845 与 582227/582231,
--    相位 0)并已承担同 NPC 的其他日常(Compy Stomp 等),
--    故补注册到 67985/67998, 不新建刷怪。
-- 2. quest_poi/quest_poi_points 存在指向不存在任务的死数据:
--    32296 / 32475 / 32507 / 32549 (quest_template 中无此任务), 清理。
-- 3. 70371(Lor'themar 90级变体)/69741(Jaina 90级变体)存在少量
--    starter/ender 死行, 但同任务均已注册已刷替代 entry
--    (67990/67992/70370), 不影响可用性, 保留不动。
-- ============================================================

-- 1) Forge Ahead! 补注册(发放+交付)
DELETE FROM `creature_queststarter` WHERE `quest` IN (32292, 32587);
DELETE FROM `creature_questender`   WHERE `quest` IN (32292, 32587);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(67985, 32292), -- Scout Captain Elsia (部落)
(67998, 32587); -- Scout Captain Daelin (联盟)
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(67985, 32292),
(67998, 32587);

-- 2) 清理指向不存在任务的 POI 死数据
DELETE FROM `quest_poi`        WHERE `QuestID` IN (32296, 32475, 32507, 32549);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (32296, 32475, 32507, 32549);
