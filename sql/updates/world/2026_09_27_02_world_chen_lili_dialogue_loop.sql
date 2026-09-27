-- 2026_09_27_02_world_chen_lili_dialogue_loop.sql
-- 世界 NPC 陈（56133, guid 512655）与丽丽（56138, guid 512656）循环对话：
--   丽丽开场，6 句台词，第 4 句间隔 5 秒其余 6 秒，说完后约 20 秒再次循环。
-- 时序（周期内）：丽丽L1 @0 → 陈L2 @6 → 丽丽L3 @12 → 丽丽L4 @17(+5s) → 陈L5 @23 → 丽丽L6 @29 → 静默 ~20s → 循环（周期 49s）
-- 实现要点：
--   * 对话全部由陈的脚本主导；丽丽的台词用 SMART_ACTION_TALK(1) 定向
--     SMART_TARGET_CREATURE_GUID(10) 让丽丽开口（useTalkTarget=0 时 talker=目标生物）。
--   * 【必须挂 GUID】：SmartScript::GetScript 是 GUID 优先且非叠加——guid 上有脚本时
--     entry 脚本完全不加载。56133 entry 上已有任务脚本（接任务施法 105835 召唤护送
--     NPC、GOSSIP 传送酿造点），故 id 0-2 为 entry 脚本原样复制，漏抄会弄坏任务。
--   * UPDATE_OOC(事件1) 触发于 mEvents 迭代上下文，创建 mStoredEvents 延时事件安全
--     （不同容器）；各延时事件触发后只执行 TALK，不创建新事件（防崩溃模式）。
--   * creature_text：56133 已有酿造任务文本（组 0-4），陈用组 10/11；丽丽用组 0-3。
--   * Type=12 = CHAT_MSG_MONSTER_SAY（本分支 creature_text.Type 直接用 ChatMsg 枚举）。

-- ===== 对话文本 =====
DELETE FROM `creature_text` WHERE `CreatureID` = 56133 AND `GroupID` IN (10, 11);
DELETE FROM `creature_text` WHERE `CreatureID` = 56138 AND `GroupID` IN (0, 1, 2, 3);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Comment`) VALUES
(56138, 0, 0, '说走吧，陈叔！我们还等什么呢？', 12, 0, 100, 0, 'Li Li World - Dialogue Loop L1'),
(56133, 10, 0, '别着急，丽丽。我们有大把的时间来探索潘达利亚。花点时间来享受这个旅程吧！', 12, 0, 100, 0, 'Chen World - Dialogue Loop L2'),
(56138, 1, 0, '我是想"享受"旅程，可那也得先"出发"才行！', 12, 0, 100, 0, 'Li Li World - Dialogue Loop L3'),
(56138, 2, 0, '再这么磨蹭，我们哪儿都不用去了！走啦！我们得到谷中去探险！', 12, 0, 100, 0, 'Li Li World - Dialogue Loop L4'),
(56133, 11, 0, '别那么急，丽丽。我就是这么游历卡利姆多的：一次一站。', 12, 0, 100, 0, 'Chen World - Dialogue Loop L5'),
(56138, 3, 0, '难怪你花了这么长时间。你一直坐着的话，什么收获也不会有。', 12, 0, 100, 0, 'Li Li World - Dialogue Loop L6');

-- ===== 陈（guid 512655）脚本：任务脚本原样复制 + 循环对话 =====
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = -512655;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
-- ===== 原 entry 56133 任务脚本（GUID 优先会屏蔽 entry 脚本，必须原样带上） =====
(-512655, 0, 0, 0, 19, 0, 100, 0, 30073, 0, 0, 0, 0, 80, 5613300, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Quest Accept - Run Time Script'),
(-512655, 0, 1, 0, 19, 0, 100, 0, 29907, 0, 0, 0, 0, 85, 105835, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'On quest accept - Summon chen & li li'),
(-512655, 0, 2, 0, 62, 0, 100, 0, 56133, 0, 0, 0, 0, 62, 870, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, -741.452, 1301.13, 116.105, 1.866, 'Gossip Select - Teleport To Brewing Site'),
-- ===== 循环对话驱动：UPDATE_OOC 每 49s 触发，LINK 链批量创建 6 个台词延时事件（安全上下文） =====
(-512655, 0, 10, 11, 1, 0, 100, 0, 1000, 1000, 49000, 49000, 0, 67, 30, 500, 500, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Dialogue Loop - Create Timed 30 (Li Li L1 @+0.5s)'),
(-512655, 0, 11, 12, 61, 0, 100, 0, 0, 0, 0, 0, 0, 67, 31, 6500, 6500, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Dialogue Loop - Create Timed 31 (Chen L2 @+6.5s)'),
(-512655, 0, 12, 13, 61, 0, 100, 0, 0, 0, 0, 0, 0, 67, 32, 12500, 12500, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Dialogue Loop - Create Timed 32 (Li Li L3 @+12.5s)'),
(-512655, 0, 13, 14, 61, 0, 100, 0, 0, 0, 0, 0, 0, 67, 33, 17500, 17500, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Dialogue Loop - Create Timed 33 (Li Li L4 @+17.5s, +5s)'),
(-512655, 0, 14, 15, 61, 0, 100, 0, 0, 0, 0, 0, 0, 67, 34, 23500, 23500, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Dialogue Loop - Create Timed 34 (Chen L5 @+23.5s)'),
(-512655, 0, 15, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 67, 35, 29500, 29500, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Dialogue Loop - Create Timed 35 (Li Li L6 @+29.5s)'),
-- ===== 台词执行（只 TALK，不创建新事件；陈 target 0 自己说，丽丽 target 10 定向 GUID） =====
(-512655, 0, 20, 0, 59, 0, 100, 0, 30, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 10, 512656, 56138, 0, 0, 0, 0, 0, 0, 'Li Li - Timed 30 - Say L1'),
(-512655, 0, 21, 0, 59, 0, 100, 0, 31, 0, 0, 0, 0, 1, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Timed 31 - Say L2'),
(-512655, 0, 22, 0, 59, 0, 100, 0, 32, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 10, 512656, 56138, 0, 0, 0, 0, 0, 0, 'Li Li - Timed 32 - Say L3'),
(-512655, 0, 23, 0, 59, 0, 100, 0, 33, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 10, 512656, 56138, 0, 0, 0, 0, 0, 0, 'Li Li - Timed 33 - Say L4'),
(-512655, 0, 24, 0, 59, 0, 100, 0, 34, 0, 0, 0, 0, 1, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Timed 34 - Say L5'),
(-512655, 0, 25, 0, 59, 0, 100, 0, 35, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 10, 512656, 56138, 0, 0, 0, 0, 0, 0, 'Li Li - Timed 35 - Say L6');
