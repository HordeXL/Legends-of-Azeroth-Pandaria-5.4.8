-- 2026_10_12_04_world_quest_29950_lili_day_off.sql
-- 任务 29950「丽丽的假日」完成机制修复（方案 B：忠实官方召唤+跟随 + 三地 credit）
--
-- 官方机制（DBC 实测还原）：
--   接任务得许愿石 76350（使用=法术 106276 效果 SUMMON creature 56549 探索版丽丽，
--   SummonProperties 3175 Category=1/Type=0/Slot=6/Flags 0x228D8 含 0x10=私有召唤，
--   对接任务的玩家本人可见——官方正确语义，无需改 DBC）。
--   玩家带探索丽丽到三地 → credit 56546/56547/56548。
--   official_ref.smart_scripts 里 56549 亦无行（官方触发在客户端 DBC 区域法术，本 fork 缺失）。
--
-- 本地实现：
--   PART 1 探索丽丽 56549：召唤后跟随召唤者（target 23 OWNER_OR_SUMMONER）+ 被动反应 +
--     IMMUNE_TO_PC（官方丽丽不参战、不可被选中）。
--   PART 2 三地 credit 触发：复用在位的 Generic Bunny - PRK 41200 三个点位 guid
--     （514794 丝纱工坊 area5986 / 513945 新希菲拉 area5973 / 515670 黄泽瀑布 area6021，
--     位置与官方 POI 及地标 NPC 吻合），GUID 级 OOC_LOS(25码) → 条件 QUESTTAKEN(9) 29950
--     → CALL_KILLEDMONSTER(target 7 invoker)。entry 级 41200 已有官方 SAI（SpellHit 106299
--     雷雨召唤），绝不覆盖——必须 GUID 级。
--   PART 3 丽丽三地台词（wiki 实机还原）。触发点 TALK 用 target 19 CREATURE_RANGE(56549, 20)
--     命中玩家身旁的探索丽丽（guid 随召唤变化，不能用 target 10）。
--
-- 本核心 SAI 编号：OOC_LOS=10、LINK=61、TIMED_EVENT_TRIGGERED=59、JUST_SUMMONED=54、
--   CALL_KILLEDMONSTER=33(target 7=invoker)、TALK=1、CREATE_TIMED_EVENT=67、
--   FOLLOW=29(target 23=OWNER_OR_SUMMONER)、SET_REACT_STATE=8、CREATURE_RANGE=19。
-- 条件键：SAI 事件 SourceType=22, SourceEntry=entryorguid(负), SourceGroup=行id+1, SourceId=0。
--
-- 已应用 world 库；生效：重启 worldserver（AIName 变更）。

-- ===== PART 1: 探索丽丽 56549 =====
UPDATE `creature_template` SET `AIName` = 'SmartAI', `unit_flags` = `unit_flags` | 33554432 WHERE `entry` = 56549;

DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = 56549;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
-- 召唤后：被动 + 800ms 后跟随召唤者（dist 3）——延时发起避开 AddToWorld 时序（memory 经验1）
(56549, 0, 0, 1, 54, 0, 100, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Li Li Explorer - Just Summoned - Set Passive'),
(56549, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 67, 1, 800, 800, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Li Li Explorer - Link - Create Timed 1 (@800ms)'),
(56549, 0, 10, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 29, 3, 0, 0, 0, 0, 0, 23, 0, 0, 0, 0, 0, 0, 0, 0, 'Li Li Explorer - Timed 1 - Follow Summoner (dist 3)');

-- ===== PART 2: 三地 credit 触发（GUID 级，挂在在位 PRK bunny 上） =====
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` IN (-514794, -513945, -515670);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
-- 丝纱工坊（guid 514794）：OOC_LOS 25 码冷却 15-30s → credit 56546 → 丽丽台词组 0/1
(-514794, 0, 0, 1, 10, 0, 100, 0, 1, 25, 15, 30, 1, 33, 56546, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Silken Fields - LOS Player With Q29950 - Credit 56546'),
(-514794, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 19, 56549, 20, 0, 0, 0, 0, 0, 0, 'Silken Fields - Link - Li Li Say G0'),
(-514794, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 19, 56549, 20, 0, 0, 0, 0, 0, 0, 'Silken Fields - Link - Li Li Say G1'),
-- 新希菲拉（guid 513945）→ credit 56547 + 台词组 2/3
(-513945, 0, 0, 1, 10, 0, 100, 0, 1, 25, 15, 30, 1, 33, 56547, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'New Cifera - LOS Player With Q29950 - Credit 56547'),
(-513945, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 19, 56549, 20, 0, 0, 0, 0, 0, 0, 'New Cifera - Link - Li Li Say G2'),
(-513945, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 19, 56549, 20, 0, 0, 0, 0, 0, 0, 'New Cifera - Link - Li Li Say G3'),
-- 黄泽瀑布（guid 515670）→ credit 56548 + 台词组 4/5
(-515670, 0, 0, 1, 10, 0, 100, 0, 1, 25, 15, 30, 1, 33, 56548, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Huangtze Falls - LOS Player With Q29950 - Credit 56548'),
(-515670, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 1, 4, 0, 0, 0, 0, 0, 19, 56549, 20, 0, 0, 0, 0, 0, 0, 'Huangtze Falls - Link - Li Li Say G4'),
(-515670, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 1, 5, 0, 0, 0, 0, 0, 19, 56549, 20, 0, 0, 0, 0, 0, 0, 'Huangtze Falls - Link - Li Li Say G5');

-- SAI 事件条件：三个 bunny 的 LOS 行（id 0 → SourceGroup=1）挂 QUESTTAKEN 29950
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` IN (-514794, -513945, -515670);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, -514794, 0, 0, 9, 0, 29950, 0, 0, 0, 0, 0, '', 'Silken Fields LOS credit only when quest 29950 in progress'),
(22, 1, -513945, 0, 0, 9, 0, 29950, 0, 0, 0, 0, 0, '', 'New Cifera LOS credit only when quest 29950 in progress'),
(22, 1, -515670, 0, 0, 9, 0, 29950, 0, 0, 0, 0, 0, '', 'Huangtze Falls LOS credit only when quest 29950 in progress');

-- ===== PART 3: 探索丽丽台词（wiki 实机还原） =====
DELETE FROM `creature_text` WHERE `CreatureID` = 56549;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Comment`) VALUES
(56549, 0, 0, '快看这些华丽的丝绸！', 12, 0, 100, 0, 'Li Li - Silken Fields A'),
(56549, 1, 0, '你觉得这些东西真是从蚕宝宝的屁股里弄出来的吗？', 12, 0, 100, 0, 'Li Li - Silken Fields B'),
(56549, 2, 0, '看这个！', 12, 0, 100, 0, 'Li Li - New Cifera A'),
(56549, 3, 0, '这上面有个村庄……还有一尊大鱼雕像。你觉得是锦鱼人建的吗？', 12, 0, 100, 0, 'Li Li - New Cifera B'),
(56549, 4, 0, '嘿！快看那个瀑布！', 12, 0, 100, 0, 'Li Li - Huangtze Falls A'),
(56549, 5, 0, '你应该养成习惯，总去瀑布后面看看有没有山洞。', 12, 0, 100, 0, 'Li Li - Huangtze Falls B');
