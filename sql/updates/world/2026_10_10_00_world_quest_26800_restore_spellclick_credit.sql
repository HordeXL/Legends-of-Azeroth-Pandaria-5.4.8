-- ============================================================================
-- 恢复任务 26800「Recruitment」的正确计数逻辑（spellclick + 直接给计数）
--
-- 【背景】本库曾于 2026-09-07 修过一次（见另一仓库
--   E:\GitHub\LoA-5.4.8\sql\updates\world\2026_09_07_00_world_quest_26800_scarlet_corpse_credit.sql），
--   但 2026-10-08 的排查过程中 49340 的 smart_scripts 被还原成了2022 社区版
--   （event 75 距离触发，dist=3），**丢失了计数动作**，导致任务再次卡住。
--   本脚本恢复 9 月的正确方案，并移除 10-08 基于错误前提做的两项改动。
--
-- 【为什么必须恢复 CALL_KILLEDMONSTER】
--   quest_objective: questId=26800, type=0(MONSTER), objectId=49340, amount=6
--   "收集血色十字军尸体"。**type=0 的计数只由 Player::KilledMonsterCredit(49340) 推进**。
--   2022 社区版的尸体 SAI 里**没有任何 CALL_KILLEDMONSTER 动作**，其 id0/id1
--   走的是"距离达内尔 → 施放 91945 → 46598"，id2 的 DATA_SET 1,1 只在
--   **交任务时**由 174001 脚本组统一发出 —— 运行期从不发。
--   → 尸体既不会消失、也不会给计数，计数永远 0/6。
--
-- 【本脚本恢复的 4 行】(同 2026-09-07 方案)
--   id0 event73 (ON_SPELLCLICK) link1 → action33 CALL_KILLEDMONSTER
--                                         param1=49340, target_type=7(ACTION_INVOKER)
--                                         ★计数：直接给点击者(玩家) +1
--   id1 link2 → action11 cast 46598 target_type=19(CLOSEST_CREATURE) param1=49337
--                → 达内尔(49337) SAI "On Spell Hit 46598 → Cast 91935 Self(倒地)"
--                  做出"捡起尸体"的表现
--   id2 link2 → action41 FORCE_DESPAWN param1=1000 (延迟1秒) → 尸体消失、60秒重生
--   id3 event38 DATA_SET 1,1 → action41 despawn（保留交任务时的清理逻辑）
--
-- 【target_type=7 (ACTION_INVOKER) 在此是正确的，与 29524 的结论不冲突】
--   29524 不能用 ACTION_INVOKER，是因为它由 SMART_EVENT_HEALTH_PCT 触发，
--   走 Update tick 的 timed event → ProcessTimedAction() **不带 unit**，
--   invoker 为 NULL 只能回退 GetLastInvoker（已被 OnReset 清除）→ 解析空表。
--   而本行是 **SMART_EVENT_ON_SPELLCLICK(73)**，走
--   SmartAI::OnSpellClick → ProcessEventsFor(..., clicker) →
--   ProcessEvent → **ProcessAction(e, unit=clicker, ...)** 携带clicker，
--   ACTION_INVOKER 能正确解析为点击者。**此处必须用 7，不能用 0**。
--
-- 【移除 10-08 的错误改动】
--   - 事件类型 73(ON_SPELLCLICK) → 75(DISTANCE_CREATURE)：还原（spellclick 才是正解）
--   - event_param3 dist 3→25：还原为 3（3 码在本fork 网格判定下本就够不到，
--     但既然 spellclick 才是主触发，该行不参与触发，无需放宽）
--   - event_param4 repeat 0→10000：还原为 0（event_flags=1 NOT_REPEATABLE
--     已保证尸体一生只触发一次）
--
-- 【生效方式】需重启 worldserver（已生成的 NPC 不会被 .reload smart_scripts
--   刷新，必须让尸体重新走InitializeAI）。
-- ============================================================================

-- 1) 备份（幂等：仅首次执行；LIKE 保留主键，避免重复行）
CREATE TABLE IF NOT EXISTS `backup_sai_49340_before_restore_20261010` LIKE `smart_scripts`;
INSERT IGNORE INTO `backup_sai_49340_before_restore_20261010`
SELECT * FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid`=49340;

-- 2) 恢复为 9 月的 spellclick + 计数方案
DELETE FROM `smart_scripts` WHERE `entryorguid`=49340 AND `source_type`=0;

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,
 `target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(49340,0,0,1,73,0,100,1,0,0,0,0,0,
 33,49340,0,0,0,0,0,
 7,0,0,0,0,0,0,0,0,
 'Scarlet Corpse - On SpellClick - Give Kill Credit (Quest 26800) to Clicker'),
(49340,0,1,2,61,0,100,0,0,0,0,0,0,
 11,46598,2,0,0,0,0,
 19,49337,20,0,0,0,0,0,0,
 'Scarlet Corpse - On SpellClick (Link) - Cast Spell 46598 on Darnell'),
(49340,0,2,0,61,0,100,0,0,0,0,0,0,
 41,1000,0,0,0,0,0,
 1,0,0,0,0,0,0,0,0,
 'Scarlet Corpse - On SpellClick (Link) - Despawn Self (1s)'),
(49340,0,3,0,38,0,100,1,1,1,0,0,0,
 41,0,0,0,0,0,0,
 1,0,0,0,0,0,0,0,0,
 'Scarlet Corpse - On Data Set 1 1 - Despawn Self');

-- 3) 校验
SELECT '=== 恢复后 49340 SAI (应为 4 行, id0=event73+action33+target7) ===' AS `check`;
SELECT entryorguid, id, link, event_type, event_chance, event_flags,
       event_param1, event_param2, event_param3, event_param4,
       action_type, action_param1, action_param2,
       target_type, target_param1, target_param2, comment
FROM `smart_scripts`
WHERE source_type=0 AND entryorguid=49340
ORDER BY id;

SELECT '=== 计数行必须满足: event73 + action33 + param49340 + target7 ===' AS `check`;
SELECT COUNT(*) AS credit_row_ok FROM `smart_scripts`
WHERE source_type=0 AND entryorguid=49340 AND id=0
  AND event_type=73 AND action_type=33
  AND action_param1=49340 AND target_type=7;

SELECT '=== 行数应为 4 ===' AS `check`;
SELECT COUNT(*) AS rows_now FROM `smart_scripts`
WHERE source_type=0 AND entryorguid=49340;

SELECT '=== 模板 AI 必须是 SmartAI 且无悬空ScriptName ===' AS `check`;
SELECT entry, name, npcflag, AIName, ScriptName FROM `creature_template` WHERE entry=49340;

SELECT '=== 达内尔拾取反应链完整(49337 id5) ===' AS `check`;
SELECT id, event_type, event_param1, action_type, action_param1, comment
FROM `smart_scripts` WHERE source_type=0 AND entryorguid=49337 AND event_type=8;

SELECT '=== 计数目标未受损 ===' AS `check`;
SELECT questId, type, objectId, amount, description FROM `quest_objective` WHERE questId=26800;