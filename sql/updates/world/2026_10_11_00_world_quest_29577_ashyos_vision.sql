-- 2026_10_11_00_world_quest_29577_ashyos_vision.sql
-- 任务 29577「阿西约的预见」完成机制修复（官方还原：对话选 gossip 触发仪式演出 + credit）
--
-- 官方机制（warcraft.wiki.gg 实机记录）：
--   接任务后阿西约在净水池顶部（本地静态刷新 guid 513897 已在位 374.6,353.5,186）；
--   玩家与他对话选 gossip 选项 → 阿西约把手杖插进水里（演出）→ 系列台词
--   （阿西约/莲花农/丽丽/张跃）→ 任务完成 credit 56113 → 回张跃 56802 交付。
-- 官方 dump（official_ref）无 SAI/gossip 数据（与 29919/29952 同批，机制在 gossip 表）。
--
-- 设计要点：
--   * credit 在 gossip 选择的 LINK 链第一步立即发放（保证任务必完成），
--     演出台词走定时事件，不承载完成逻辑。
--   * 56113 是 29871 的交付 NPC：npcflag 增配 gossip 位(1)，任务交付优先，菜单在无交付时显示。
--   * gossip_menu_id 必须指向 56113（实测教训：漏配则 PrepareGossipMenu 拿到 menuId=0，
--     选项永远为空，客户端只显示任务发放者默认问候）
--   * gossip 选项挂 QUESTTAKEN(9) 29577 条件 —— 只有持任务玩家可见。
--   * SAI 用 entry 级（56113）：两个 guid（513897 Pools 顶部 / 514068 幻象位）行为一致无害。
--   * 本核心 SAI 编号：GOSSIP_SELECT=62、LINK=61、TIMED_EVENT_TRIGGERED=59、
--     CALL_KILLEDMONSTER=33(target 7=invoker)、TALK=1、CREATE_TIMED_EVENT=67、PLAY_EMOTE=5、
--     CLOSE_GOSSIP=72、CREATURE_RANGE=19(target param1=entry, param2=距离)。
--   * 条件键：SourceType=15(gossip_menu_option), SourceGroup=MenuID, SourceEntry=OptionID。

-- ===== 1. 模板：开 SmartAI + gossip 位 =====
UPDATE `creature_template` SET `AIName` = 'SmartAI', `npcflag` = `npcflag` | 1, `gossip_menu_id` = 56113 WHERE `entry` = 56113;

-- ===== 2. gossip 菜单 =====
DELETE FROM `gossip_menu` WHERE `MenuID` = 56113;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`, `VerifiedBuild`) VALUES (56113, 56113, 0);

DELETE FROM `npc_text` WHERE `ID` = 56113;
INSERT INTO `npc_text` (`ID`, `text0_0`, `text0_1`, `VerifiedBuild`) VALUES
(56113, '这水……我看见了。你也要看看吗？', '这水……我看见了。你也要看看吗？', 0);

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 56113;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcflag`, `ActionMenuID`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(56113, 0, 0, '开始仪式吧，阿西约。', 0, 1, 1, 0, NULL, 0, 0);

-- 选项可见性：仅持任务 29577 的玩家
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceEntry` = 56113 AND `SourceGroup` = 56113;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(15, 56113, 0, 0, 0, 9, 0, 29577, 0, 0, 0, 0, 0, '', 'Ashyo ritual gossip - show while quest 29577 taken');

-- ===== 3. 台词 =====
DELETE FROM `creature_text` WHERE `CreatureID` = 56113 AND `GroupID` IN (0,1,2);
DELETE FROM `creature_text` WHERE `CreatureID` = 56802 AND `GroupID` IN (0);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Comment`) VALUES
(56113, 0, 0, '我以前只做过一次……希望这次能成。', 12, 0, 100, 0, 'Ashyo ritual - L1'),
(56113, 1, 0, '这……这是什么地方？真美……可是……有些不对劲。', 12, 0, 100, 0, 'Ashyo ritual - L2'),
(56802, 0, 0, '怎么会？锦鱼人真能这么轻易地接入水之力吗？', 12, 0, 100, 0, 'Zhang Yue ritual - L3');

-- ===== 4. SAI（entry 级） =====
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = 56113;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
-- 对话选项 0 → 关闭 gossip + LINK 链
(56113, 0, 0, 1, 62, 0, 100, 0, 56113, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ashyo - Gossip Select Option 0 - Close Gossip'),
(56113, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 33, 56113, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Ashyo - Link - Quest Credit 56113 To Invoker'),
-- 演出链：T1 台词 L1(+1s) → 杖入水 emote(+2s) → T2 台词 L2(+6s) → 张跃插话(+10s)
(56113, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 67, 1, 1000, 1000, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ashyo - Link - Create Timed 1 (L1 @1s)'),
(56113, 0, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 67, 2, 2000, 2000, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ashyo - Link - Create Timed 2 (Emote @2s)'),
(56113, 0, 4, 5, 61, 0, 100, 0, 0, 0, 0, 0, 0, 67, 3, 6000, 6000, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ashyo - Link - Create Timed 3 (L2 @6s)'),
(56113, 0, 5, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 67, 4, 10000, 10000, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Ashyo - Link - Create Timed 4 (Zhang Yue @10s)'),
-- 定时执行（只演出，不再创建事件——防 mStoredEvents 迭代失效崩溃）
(56113, 0, 10, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ashyo - Timed 1 - Say L1'),
(56113, 0, 11, 0, 59, 0, 100, 0, 2, 0, 0, 0, 0, 5, 133, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ashyo - Timed 2 - Emote 133 (use standing, staff into pool)'),
(56113, 0, 12, 0, 59, 0, 100, 0, 3, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Ashyo - Timed 3 - Say L2'),
(56113, 0, 13, 0, 59, 0, 100, 0, 4, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 19, 56802, 45, 0, 0, 0, 0, 0, 0, 'Zhang Yue - Timed 4 - Say L3 (nearby)');
