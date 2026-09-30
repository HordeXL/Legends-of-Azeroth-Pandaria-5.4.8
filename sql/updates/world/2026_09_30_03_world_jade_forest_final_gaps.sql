-- 2026_09_30_03_world_jade_forest_final_gaps.sql
-- 翡翠林全任务链审计（325 任务）的收尾修复：补最后 2 个真实断点的 NPC spawn。
--
-- 背景（2026_09_30 审计结论）：
--   链引用 0 悬空；与 official_ref 逐字段一致；幼龙系列已在
--   2026_09_30_02 修复。剩余真断点仅 2 个任务，其余 NO_SPAWN 记录
--   均为多模板冗余（同任务存在有 spawn 的替代 NPC）。
--
-- 断点 1: 29733 军情七处报告：丛林迷失 (SI:7 Report: Lost in the Woods)
--   发放/交付 = Rell Nightwind 55333（无 spawn），目标信用 = 67152
--   "Rell's Story Credit"（隐形触发器，无 spawn）。
--   官方位置：珍珠村 SI:7 营地（POI 起点 -157,-2642；队友 55282/55283/60970/66949
--   均在 -148~-162, -2649~-2668, z≈0.2~1.5）。
--
-- 断点 2: 30565 意外之喜 (An Unexpected Advantage)
--   发放/交付 = Sully "The Pickle" McLeary 59550（无 spawn）。
--   目标 = 猢狲伏击者掉落 80176/80177（沿盘山道伏击圈），交任务 POI
--   (-178,-2637) = 珍珠村南缘 → Sully 落点在珍珠村 55282 附近。

DELETE FROM `creature` WHERE `id` IN (55333, 59550, 67152);
INSERT INTO `creature`
  (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `modelid`, `equipment_id`,
   `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `spawntimesecs_max`,
   `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`,
   `npcflag`, `npcflag2`, `unit_flags`, `unit_flags2`, `dynamicflags`, `ScriptName`, `walk_mode`, `VerifiedBuild`)
VALUES
  -- 55333 Rell Nightwind（29733 发放/交付，珍珠村 SI:7 营地）
  (4002009, 55333, 870, 5785, 5935, 1, 1, 0, 0, -150.50, -2646.50, 0.25, 2.10, 300, 300, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, '', 0, 18414),
  -- 67152 Rell's Story Credit（29733 目标信用隐形触发器，紧邻 Rell）
  (4002010, 67152, 870, 5785, 5935, 1, 1, 0, 0, -152.00, -2647.50, 0.25, 2.10, 300, 300, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, '', 0, 18414),
  -- 59550 Sully（30565 意外之喜 发放/交付，珍珠村 55282 旁）
  (4002011, 59550, 870, 5785, 5935, 1, 1, 0, 0, -161.50, -2653.50, 0.35, 5.60, 300, 300, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, '', 0, 18414);
