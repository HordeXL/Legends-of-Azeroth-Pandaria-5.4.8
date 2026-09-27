-- 2026_09_27_01_world_lili_56138_patrol.sql
-- 丽丽（entry 56138，guid 512656）循环巡逻路径：
--   A(524.007,-694.835,247.354 = 刷新点) → B(513.98,-703.44,246.82) → 返回 A → 停 15 秒 → 循环
-- 实现：GUID 级 SmartAI（entryorguid = -512656）。
-- 【关键】每次移动都不得在 MOVEMENTINFORM 上下文中直接发起：
--   MotionMaster 竞态——DirectExpire 清理同步触发 MOVEMENTINFORM，此刻推入的新
--   MovePoint 生成器会被误删（陈护送 05 版断链的同一根因）。因此到站后一律先
--   创建 250ms 延时事件，由 TIMED_EVENT_TRIGGERED 上下文发起下一段移动。
--   回到 A 后的 15 秒等待同样由延时事件承载（单次创建，防 mStoredEvents 悬挂）。
-- 脚本挂在 guid 上，不影响其他 56138 实例。

UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 56138;

DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = -512656;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
-- 出生/复活于 A：立即步行走向 B（point 1）——出生上下文可直接移动
(-512656, 0, 0, 0, 25, 0, 100, 0, 0, 0, 0, 0, 0, 69, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 513.98, -703.44, 246.82, 0, 'Li Li - On Respawn - Move To B (point 1)'),
-- 到达 B：创建 250ms 延时事件（移动事件上下文不可直接发起移动）
(-512656, 0, 1, 0, 34, 0, 100, 0, 0, 1, 0, 0, 0, 67, 11, 250, 250, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Li Li - Reached B - Create Timed 11 (@250ms)'),
-- 延时触发：步行返回 A（point 2）
(-512656, 0, 2, 0, 59, 0, 100, 0, 11, 0, 0, 0, 0, 69, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 524.007, -694.835, 247.354, 0, 'Li Li - Timed 11 - Move Back To A (point 2)'),
-- 到达 A：创建 15 秒延时事件（等待循环间隔）
(-512656, 0, 3, 0, 34, 0, 100, 0, 0, 2, 0, 0, 0, 67, 10, 15000, 15000, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Li Li - Reached A - Create Timed 10 (Wait 15s)'),
-- 延时触发：再次走向 B（循环）
(-512656, 0, 4, 0, 59, 0, 100, 0, 10, 0, 0, 0, 0, 69, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 513.98, -703.44, 246.82, 0, 'Li Li - Timed 10 - Move To B (point 1, loop)');
