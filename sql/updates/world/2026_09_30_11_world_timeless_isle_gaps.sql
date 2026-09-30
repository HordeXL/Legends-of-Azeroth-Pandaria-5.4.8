-- ============================================================
-- 2026_09_30_11_world_timeless_isle_gaps.sql
-- 永恒岛(Timeless Isle, WorldMapAreaId 951)任务链修复
--
-- 发现(2026-09-30 审计):
-- 1. 33228 "Time In Your Hands" 无任何发放/交付注册, 玩家无法获取。
--    官方(Wowhead infobox) Start/End 均为 Kairoz(npc 72870), 本库
--    Kairoz 已刷出(map 870, -624.9, -4912.7), 补注册即可。
--    官方数据(official_ref)亦无该任务的 addon 行, 故不加前置,
--    与官方一致(到达 Kairoz 即可选)。
-- 2. 32976 "Rolo's Riddle"(第三步) 缺 quest_template_addon 行;
--    官方库同样缺失, 但同链 32974/32975 均有显式行, 补全默认行
--    以保证确定性。该链第一步 32974 由物品 102225 "Rolos Riddle"
--    (startquest) 开链, 属官方设计, 无需 NPC 注册。
-- 3. 33098 "Secrets of the Timeless Isle" 的 Emperor Shaohao 崇拜
--    门槛(1359/42000)与汇聚组 -33098 经 official_ref 比对确认
--    为官方原始数据, 保留不动。
-- 4. 其余 36 个 POI 任务: 无悬空引用, 全部 starter/ender 有存活
--    刷怪(Kairoz/Master Li/Emperor Shaohao/Chromie/Watcher
--    Lara/Alundra/Wrathion 等), 链条完整。
-- ============================================================

-- 1) 33228 Time In Your Hands 补 Kairoz 注册
DELETE FROM `creature_queststarter` WHERE `quest` = 33228;
DELETE FROM `creature_questender`   WHERE `quest` = 33228;
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (72870, 33228);
INSERT INTO `creature_questender`   (`id`, `quest`) VALUES (72870, 33228);

-- 2) 补缺失的 addon 行(全默认值)
INSERT INTO `quest_template_addon` (`ID`) VALUES
(32976),
(33228);
