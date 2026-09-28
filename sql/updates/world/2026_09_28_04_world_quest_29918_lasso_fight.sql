-- ============================================================
-- 任务 29918「英勇的一课」套索机制修复 v5（最终版）
-- ============================================================
-- v4 实测：落点 delay=300s 停留未生效（本核心 SmartAI 路径推进不执行
--   delay），鹰到达落点后仍立即恢复 Random 升空。飞行生物的地面行为
--   （停留/定身/追逐）经 v2/v3/v4 三轮实测均无法稳定控制。
--
-- v5 回归官方语义：官方 5.4.8 dump 本来就是"套住即完成任务"
--   （CALL_KILLEDMONSTER），真正要修的只是高空弹人摔死问题。
--   方案：套住后不立即计数，先俯冲到低空点（z=地面+2），安全弹出
--   玩家后再给 credit——保留骑鹰俯冲演出，彻底消除摔死，不依赖
--   鹰的任何战斗行为。
--
-- 流程：
--   SPELLHIT(8, 105355) -> action 53 WP_START 2 点俯冲路径
--   WAYPOINT_REACHED(40, PointId=2, 到达低空点) -> action 67 定时
--     0.2-0.35s（避开移动回调上下文；窗口内鹰爬升 2-4 码，
--     弹出高度 4-6 码，低于摔落伤害阈值）
--   TIMED_EVENT_TRIGGERED(59, id=1) 两行：
--     - action 28 移除套索光环（低空安全下鹰）
--     - action 33 CALL_KILLEDMONSTER(56171) target 21 CLOSEST_PLAYER(100)
--       -> 任务目标 0（击杀 56171）立即完成
--   鹰随后升空回家（EVADE 恢复 react=DEFENSIVE），重生(60s)复位。
--   交回套索目标（objective 1）不受影响（套索不消耗，仍在包中）。
--
-- 生效：需重启 worldserver。
-- ============================================================

-- ---- 1. 清理 v4 的 SAI 行（entry 级仅动 id2，保留官方战斗技能 id0/id1）----
DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = 56171 AND `id` = 2;
DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` IN (-512817, -512935, -513098, -516816);

-- ---- 2. 降落路径（2 点俯冲，终点=低空点；delay 归零）----
DELETE FROM `waypoints` WHERE `entry` IN (5617101, 5617102, 5617103, 5617104);
INSERT INTO `waypoints`
(`entry`, `pointid`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `point_comment`)
VALUES
(5617101, 1, 414.2, -456.9, 271.3, 0, 0, 'Plainshawk 512817 lasso descent mid'),
(5617101, 2, 422.7, -447.4, 216.0, 0, 0, 'Plainshawk 512817 lasso low point'),
(5617102, 1, 504.6, -533.5, 283.0, 0, 0, 'Plainshawk 512935 lasso descent mid'),
(5617102, 2, 501.9, -539.3, 254.2, 0, 0, 'Plainshawk 512935 lasso low point'),
(5617103, 1, 187.0, -235.7, 279.5, 0, 0, 'Plainshawk 513098 lasso descent mid'),
(5617103, 2, 190.5, -241.0, 238.0, 0, 0, 'Plainshawk 513098 lasso low point'),
(5617104, 1, 166.5, -695.6, 279.4, 0, 0, 'Plainshawk 516816 lasso descent mid'),
(5617104, 2, 176.1, -695.9, 226.9, 0, 0, 'Plainshawk 516816 lasso low point');

-- ---- 3. entry 级：EVADE 恢复 react（id2）----
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
 `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
 `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
 `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`,
 `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(56171, 0, 2, 0, 7, 0, 100, 0, 0, 0, 0, 0, 0,
 8, 1, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0,
 0, 0, 0, 0, 'Great White Plainshawk - On evade - 恢复 react=DEFENSIVE');

-- ---- 4. per-GUID SAI：套住 -> 俯冲 -> 低空弹出+计数 ----
-- guid 512817
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
 `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
 `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
 `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`,
 `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-512817, 0, 0, 0, 8, 0, 100, 0, 105355, 0, 0, 0, 0,
 53, 1, 5617101, 0, 0, 0, 2,
 0, 0, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 512817 - 被套住: WP_START 俯冲路径(run,react=AGGRESSIVE)'),
(-512817, 0, 1, 0, 40, 0, 100, 0, 2, 0, 0, 0, 0,
 67, 1, 200, 350, 0, 0, 100,
 0, 0, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 512817 - 到达低空点(点2)后 0.2-0.35s 定时'),
(-512817, 0, 2, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0,
 28, 105355, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 512817 - 低空解除套索光环(玩家安全下鹰)'),
(-512817, 0, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0,
 33, 56171, 0, 0, 0, 0, 0,
 21, 100, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 512817 - 套住即计数: CALL_KILLEDMONSTER 给最近玩家');

-- guid 512935
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
 `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
 `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
 `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`,
 `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-512935, 0, 0, 0, 8, 0, 100, 0, 105355, 0, 0, 0, 0,
 53, 1, 5617102, 0, 0, 0, 2,
 0, 0, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 512935 - 被套住: WP_START 俯冲路径(run,react=AGGRESSIVE)'),
(-512935, 0, 1, 0, 40, 0, 100, 0, 2, 0, 0, 0, 0,
 67, 1, 200, 350, 0, 0, 100,
 0, 0, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 512935 - 到达低空点(点2)后 0.2-0.35s 定时'),
(-512935, 0, 2, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0,
 28, 105355, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 512935 - 低空解除套索光环(玩家安全下鹰)'),
(-512935, 0, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0,
 33, 56171, 0, 0, 0, 0, 0,
 21, 100, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 512935 - 套住即计数: CALL_KILLEDMONSTER 给最近玩家');

-- guid 513098
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
 `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
 `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
 `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`,
 `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-513098, 0, 0, 0, 8, 0, 100, 0, 105355, 0, 0, 0, 0,
 53, 1, 5617103, 0, 0, 0, 2,
 0, 0, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 513098 - 被套住: WP_START 俯冲路径(run,react=AGGRESSIVE)'),
(-513098, 0, 1, 0, 40, 0, 100, 0, 2, 0, 0, 0, 0,
 67, 1, 200, 350, 0, 0, 100,
 0, 0, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 513098 - 到达低空点(点2)后 0.2-0.35s 定时'),
(-513098, 0, 2, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0,
 28, 105355, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 513098 - 低空解除套索光环(玩家安全下鹰)'),
(-513098, 0, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0,
 33, 56171, 0, 0, 0, 0, 0,
 21, 100, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 513098 - 套住即计数: CALL_KILLEDMONSTER 给最近玩家');

-- guid 516816
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
 `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
 `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
 `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`,
 `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(-516816, 0, 0, 0, 8, 0, 100, 0, 105355, 0, 0, 0, 0,
 53, 1, 5617104, 0, 0, 0, 2,
 0, 0, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 516816 - 被套住: WP_START 俯冲路径(run,react=AGGRESSIVE)'),
(-516816, 0, 1, 0, 40, 0, 100, 0, 2, 0, 0, 0, 0,
 67, 1, 200, 350, 0, 0, 100,
 0, 0, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 516816 - 到达低空点(点2)后 0.2-0.35s 定时'),
(-516816, 0, 2, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0,
 28, 105355, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 516816 - 低空解除套索光环(玩家安全下鹰)'),
(-516816, 0, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0,
 33, 56171, 0, 0, 0, 0, 0,
 21, 100, 0, 0, 0,
 0, 0, 0, 0, 'Plainshawk 516816 - 套住即计数: CALL_KILLEDMONSTER 给最近玩家');
