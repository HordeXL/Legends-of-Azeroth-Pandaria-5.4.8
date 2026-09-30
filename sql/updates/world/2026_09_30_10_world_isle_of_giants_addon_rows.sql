-- ============================================================
-- 2026_09_30_10_world_isle_of_giants_addon_rows.sql
-- 巨兽岛(Isle of Giants, WorldMapAreaId 929)任务链修复
--
-- 发现(2026-09-30 审计):
-- 32616 "A Large Pile of Giant Dinosaur Bones" 与
-- 32617 "A Mountain of Giant Dinosaur Bones"
-- 缺少 quest_template_addon 行(核心将取全 0 默认值, 不致命,
-- 但与同组 32613-32615 的显式数据不一致, 补齐以保证确定性)。
--
-- 其余审计结论:
-- - 32613-32617 五个骨头日常链字段正常(Prev/Next/ExclusiveGroup 全 0,
--   SpecialFlags=1 可重复);
-- - 唯一发放/交付 NPC Ku'ma(70022) 已刷出(map 870, 6043.58,1424.01,26.34,
--   与 quest_poi_points 目标点 6052,1416 吻合), 无缺口。
-- ============================================================

INSERT INTO `quest_template_addon` (`ID`) VALUES
(32616),
(32617);
