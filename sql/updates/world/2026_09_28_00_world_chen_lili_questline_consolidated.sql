-- ============================================================================
-- 2026_09_28_00_world_chen_lili_questline_consolidated.sql
-- 四风谷 陈·风暴烈酒 / 丽丽任务线 修复（合并版）
--
-- 由以下 5 个更新合并而成（均已按顺序应用并通过回读校验，本文件为幂等重放版）：
--   2026_09_28_00_world_chen_stormstout_questline_fixes.sql        （机制补齐）
--   2026_09_28_01_world_chen_hub_quest_gating.sql                  （半山枢纽门控）
--   2026_09_28_02_world_chen_chain_root_and_emperor_gate.sql       （链根 + 帝王酒多前置）
--   2026_09_28_03_world_chen_remove_legacy_exclusive_groups.sql    （清理遗留互斥组）
--   2026_09_28_04_world_lili_chain_gating.sql                      （丽丽链门控）
--
-- 数据依据：
--   * 官方 5.4.8 参考库（world_548_20240722.sql → official_ref 逐字段比对）
--   * 零售前置链（客户端 DB2）：Tauri mop-shoot（Requires 字段）、
--     Twinstar mop-twinhead、Wowpedia、db.damijing.com
--   * 本核心源码核实（见各节机制备忘）
--
-- 详细分析：docs/chen_stormstout_questline_check.md
-- ============================================================================


-- ############################################################################
-- # PART 1（原 00 号）：机制补齐——credit/拾取源/讲故事演出
-- ############################################################################
--
-- 官方核对结论：
--   * quest_template_addon / quest_objective / conditions / spell_area：
--     本地与官方逐字段一致 → "8 个任务缺 addon 行"是官方原样，不修。
--   * 29947/29950：官方机制完整（StartItem 76370/76350 + addon.ProvidedItemCount=1，
--     接任务发物品，使用时由 DBC 法术 106263/106276 发 credit），不修。
--   * 29945：花=GO 209907(loot 40521→76334，42 刷新点)、血=野兽 56523/56524/56526/56531/56532
--     (131 刷新)，机制完整，不修。
--   * 真正缺失（官方 DB 也无机制，需本服自研补齐）：
--     1) 30032 物品 77034「窖藏大麦」全库无任何拾取源（官方同样缺失）→
--        给洞穴口的"守望崖淡啤大麦"GO 210052（唯一刷新，-931,664）配 100% 任务拾取。
--     2) 29919「一醉方休」护送 credit 56571：官方无触发 → 泥盏 56474 进视野发 credit。
--     3) 29952「破灭的梦想」倾听陈的故事 credit 56680：官方无触发 → 接任务时陈讲故事
--        （复用 30073 The Emperor 的定时台词脚本模式）并发 credit。
--     4) 30172「一路桶行」credit 58341：官方无触发 → 带任务接近陈发 credit（桶行到达半山）。
--
-- 实现依据（本核心源码核实）：
--   * OOC_LOS(event 10) raw 映射：param1=noHostile, param2=maxDist, param3=cooldownMin,
--     param4=cooldownMax, param5=playerOnly（SmartScriptMgr.cpp:264 通用 raw 装载）；
--     OnMoveInLineOfSight 以触发玩家为 invoker（SmartScript.cpp:3850）→ action 33 target 7。
--   * 陈 56133 的 guid 512655 有 GUID 级脚本且 GUID 优先非叠加（2026_09_27_02 教训），
--     新增行必须 entry 与 GUID 双份。
--   * 条件键映射（ConditionMgr.cpp:1113/1390 核实）：SMART_EVENT 条件
--     SourceEntry=entryorguid（可负）、SourceGroup=smart_scripts.id+1、SourceId=source_type。
--   * 定时台词脚本模式抄自官方 5613300（The Emperor）：action 81 清/恢复 npcflag 防中途开任务。

-- ---- 1.1) 30032「寻找优质大麦」：补 77034 拾取源 ---------------------------
DELETE FROM `gameobject_loot_template` WHERE `entry` = 210052 AND `item` = 77034;
INSERT INTO `gameobject_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES
(210052, 77034, 100, 1, 0, 1, 1);

-- ---- 1.2) 29919「一醉方休」：泥盏（56474）进视野 → 发护送 credit 56571 -----
--    泥盏 npcflag=3 为任务 NPC，GOSSIP_HELLO 不触发（客户端走 QUESTGIVER_HELLO），
--    故用 OOC_LOS；两处刷新（半山 / 谷主凯酒窖旁）都有效。
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 56474;

DELETE FROM `creature_text` WHERE `CreatureID` = 56474 AND `GroupID` = 0;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Comment`) VALUES
(56474, 0, 0, '总算把你们盼来了！酒缸我洗了三遍，就等着陈老板开酿了！', 12, 0, 100, 0, 'Mudmug - Chen arrived for q29919');

DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = 56474;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(56474, 0, 0, 1, 10, 0, 100, 0, 1, 25, 15, 30, 1, 33, 56571, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Mudmug - OOC LOS player with q29919 in progress - Credit 56571'),
(56474, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Mudmug - Link - Say greeting');

-- 清理按旧（错误）键映射写入的残留行
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = 1 AND `SourceGroup` = 56474 AND `SourceId` = 0;

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = 56474 AND `SourceGroup` = 1 AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 56474, 0, 0, 47, 0, 29919, 8, 0, 0, 0, 0, '', 'Mudmug LOS credit only when quest 29919 in progress');

-- ---- 1.3) 29952「破灭的梦想」：接任务 → 陈讲故事（定时台词）→ credit 56680 -
--    entry 56133 与 guid 512655 双份（GUID 优先非叠加）。
DELETE FROM `creature_text` WHERE `CreatureID` = 56133 AND `GroupID` IN (20, 21, 22, 23);
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Comment`) VALUES
(56133, 20, 0, '坐下来吧，$n。今天我给你讲讲我们风暴烈酒家的故事。', 12, 0, 100, 0, 'Chen - q29952 Story L1'),
(56133, 21, 0, '我的爷爷酿造了整个艾泽拉斯最好的酒——这一点，连铁炉堡的矮人都不敢反驳。', 12, 0, 100, 0, 'Chen - q29952 Story L2'),
(56133, 22, 0, '丽丽总说要传承家业。孩子的梦想容易碎，可只要还有人听故事、喝好酒，梦想就永远碎不了。', 12, 0, 100, 0, 'Chen - q29952 Story L3'),
(56133, 23, 0, '哈！泥盏的老酒桶居然一路滚回了半山——改天得给它上点新漆！', 12, 0, 100, 0, 'Chen - q30172 Barrel arrived');

-- entry 56133：id3 = 接 29952 开讲；id4 = 30172 到达 credit（link 5 说收尾台词）
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = 56133 AND `id` IN (3, 4, 5);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(56133, 0, 3, 0, 19, 0, 100, 0, 29952, 0, 0, 0, 0, 80, 5613302, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Quest Accept 29952 - Run Time Script (story)'),
(56133, 0, 4, 5, 10, 0, 100, 0, 1, 25, 15, 30, 1, 33, 58341, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - OOC LOS player with q30172 in progress - Credit 58341'),
(56133, 0, 5, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 1, 23, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Link - Say barrel arrival');

-- 定时台词脚本（抄官方 5613300 模式：清 npcflag → 台词 → credit → 恢复 npcflag）
DELETE FROM `smart_scripts` WHERE `source_type` = 9 AND `entryorguid` = 5613302;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(5613302, 9, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 81, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Set NpcFlag 0'),
(5613302, 9, 1, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 1, 20, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Say Story L1'),
(5613302, 9, 2, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 1, 21, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Say Story L2'),
(5613302, 9, 3, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 1, 22, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Say Story L3'),
(5613302, 9, 4, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 33, 56680, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Kill Credit 56680 - Invoker'),
(5613302, 9, 5, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 81, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Set NpcFlag 3');

-- 29952/30172 的 LOS/接任务条件（SourceEntry=entryorguid，SourceGroup=id+1）
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` IN (56133, -512655) AND `SourceGroup` = 5 AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 5, 56133, 0, 0, 47, 0, 30172, 8, 0, 0, 0, 0, '', 'Chen LOS credit only when quest 30172 in progress'),
(22, 5, -512655, 0, 0, 47, 0, 30172, 8, 0, 0, 0, 0, '', 'Chen LOS credit only when quest 30172 in progress');

-- guid 512655（半山常驻陈）：原样保留 0-2/10-15/20-25，追加 id3(29952)/id4+5(30172)
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = -512655 AND `id` IN (3, 4, 5);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-512655, 0, 3, 0, 19, 0, 100, 0, 29952, 0, 0, 0, 0, 80, 5613302, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Quest Accept 29952 - Run Time Script (story)'),
(-512655, 0, 4, 5, 10, 0, 100, 0, 1, 25, 15, 30, 1, 33, 58341, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - OOC LOS player with q30172 in progress - Credit 58341'),
(-512655, 0, 5, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 1, 23, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Chen - Link - Say barrel arrival');

-- ---- 1.4) 顺带修正 29932 青龙寺条件行的键映射 -------------------------------
-- 2026_09_26_06 写反了 SourceGroup/SourceEntry，按 ConditionMgr 实际查找逻辑该行
-- 从未生效——本次按正确映射重写，值不变。
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 57242 AND `SourceEntry` = 1 AND `SourceId` = 0;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = 57242 AND `SourceGroup` = 1 AND `SourceId` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, 57242, 0, 0, 47, 0, 29932, 10, 0, 0, 0, 0, '', 'Elder Sage Wind-Yi q29932 talk credit/scene only when quest taken or completed');


-- ############################################################################
-- # PART 2（原 01 号）：半山枢纽任务前置门控（按零售客户端 DB2 前置链）
-- ############################################################################
--
-- 零售结构：30046 陈的决意后并行三支
--   啤酒花线 30053→30055
--   粮食线   30048→30031→30032→30047
--   水线     30049→30051→30172
--   汇合 → 30073 帝王酒 → 30074 敲门 → 30075 扫清道路 → 30078 → 30085

-- ---- 2.A 补缺失的 addon 行 --------------------------------------------------
DELETE FROM `quest_template_addon` WHERE `ID` IN (29919, 29944, 29952, 30046, 30075, 30172);
INSERT INTO `quest_template_addon`
    (`ID`, `MaxLevel`, `AllowableClasses`, `SourceSpellID`, `PrevQuestID`, `NextQuestID`, `ExclusiveGroup`,
     `RewardMailTemplateID`, `RewardMailDelay`, `RequiredSkillID`, `RequiredSkillPoints`,
     `RequiredMinRepFaction`, `RequiredMaxRepFaction`, `RequiredMinRepValue`, `RequiredMaxRepValue`,
     `ProvidedItemCount`, `SpecialFlags`, `ScriptName`) VALUES
(29919, 0, 0, 0, 29918, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''), -- 英雄所喝略同 ← 英勇的一课
(29944, 0, 0, 0, 29919, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''), -- 擒兔先擒首 ← 英雄所喝略同
(29952, 0, 0, 0, 29950, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''), -- 破碎的梦想 ← 丽丽的假日
(30046, 0, 0, 0, 29952, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''), -- 陈的决意 ← 破碎的梦想
(30075, 0, 0, 0, 30074, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''), -- 扫清道路 ← 敲门
(30172, 0, 0, 0, 30051, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''); -- 一起走 ← 寻找活水

-- ---- 2.B 30049 扛不动水：接入零售水线 ---------------------------------------
UPDATE `quest_template_addon` SET `PrevQuestID` = 30046, `NextQuestID` = 30051 WHERE `ID` = 30049;

-- ---- 2.C 粮食线环修复（30048↔30031 互为前后成环）---------------------------
UPDATE `quest_template_addon` SET `PrevQuestID` = 30046 WHERE `ID` = 30048; -- 丽丽和谷物 ← 陈的决意
UPDATE `quest_template_addon` SET `NextQuestID` = 30032 WHERE `ID` = 30031; -- 尝味 → 寻找更好的大麦
UPDATE `quest_template_addon` SET `PrevQuestID` = 30031 WHERE `ID` = 30032; -- 寻找更好的大麦 ← 尝味
UPDATE `quest_template_addon` SET `PrevQuestID` = 30032 WHERE `ID` = 30047; -- 陈的口味 ← 寻找更好的大麦

-- ---- 2.D 水线续接 -----------------------------------------------------------
UPDATE `quest_template_addon` SET `PrevQuestID` = 30049, `NextQuestID` = 30172 WHERE `ID` = 30051; -- 寻找活水

-- ---- 2.E 啤酒花线入口 -------------------------------------------------------
UPDATE `quest_template_addon` SET `PrevQuestID` = 30046 WHERE `ID` = 30053; -- 寻找啤酒花 ← 陈的决意


-- ############################################################################
-- # PART 3（原 02 号）：链根接续 + 帝王酒三支汇合门控
-- ############################################################################
--
-- 依据：Tauri mop-shoot（Requires 字段）+ Twinstar mop-twinhead + Wowpedia
--       三方一致的零售前置数据；多前置采用本核心 each-from-all 机制。
--
-- 机制备忘（本核心）：
--   * addon.NextQuestID 也会给下游任务累积 DependentPreviousQuests（ObjectMgr.cpp:4967）
--   * ExclusiveGroup < 0 不互斥（SatisfyQuestExclusiveGroup 对 <=0 直接放行），
--     仅用于 "each-from-all"：prev 命中组内任一任务时，要求组内全部完成

-- ---- 3.A 链根接续：英勇的一课 ← 穿透獠牙与流涎之颚（雷蹄牧场支线） ----------
-- Tauri 29918 页面: "Requires Piercing Talons and Slavering Jaws (29916)"
-- 29916 官方无 addon 行（无前置），发放者 56208，直接作为牧场支线根
UPDATE `quest_template_addon` SET `PrevQuestID` = 29916, `NextQuestID` = 29919 WHERE `ID` = 29918;

-- ---- 3.B 补齐链内镜像 next 指针（与已设 prev 双向一致） ----------------------
-- 注：next 在本核心同样是门控（下游 DependentPreviousQuests），
--     与已设 prev 语义重复但保持链路对称、可双向遍历
UPDATE `quest_template_addon` SET `NextQuestID` = 29944 WHERE `ID` = 29919;
UPDATE `quest_template_addon` SET `NextQuestID` = 29946 WHERE `ID` = 29944;
UPDATE `quest_template_addon` SET `NextQuestID` = 29949 WHERE `ID` = 29946;
UPDATE `quest_template_addon` SET `NextQuestID` = 29950 WHERE `ID` = 29949;
UPDATE `quest_template_addon` SET `NextQuestID` = 29952 WHERE `ID` = 29950;
UPDATE `quest_template_addon` SET `NextQuestID` = 30046 WHERE `ID` = 29952;
UPDATE `quest_template_addon` SET `NextQuestID` = 30031 WHERE `ID` = 30048;
UPDATE `quest_template_addon` SET `NextQuestID` = 30075 WHERE `ID` = 30074;
UPDATE `quest_template_addon` SET `NextQuestID` = 30078 WHERE `ID` = 30075;
UPDATE `quest_template_addon` SET `NextQuestID` = 30085 WHERE `ID` = 30078;
-- 恢复官方 30172.next=30073（本地此前为 0）——30073 多前置检查的入口之一
UPDATE `quest_template_addon` SET `NextQuestID` = 30073 WHERE `ID` = 30172;

-- ---- 3.C 帝王酒 30073 三支汇合门控（each-from-all） -------------------------
-- 零售（Twinstar/Tauri/Wowpedia 一致）: 30073 Requires 30047 + 30055 + 30172 全部完成
-- 实现：三支线终点同负数组 → 30073 的 DependentPreviousQuests=[30047,30172]
--       （来自 30047.next/30172.next）命中后逐一校验组内全员已完成
-- 30047 原值 30047 为自指无效组，替换；30055/30172 原值 0
UPDATE `quest_template_addon` SET `ExclusiveGroup` = -30073 WHERE `ID` IN (30047, 30055, 30172);


-- ############################################################################
-- # PART 4（原 03 号）：清理遗留正数互斥组
-- ############################################################################
--
-- 背景：官方 world dump 中存在旧流程遗留的互斥组，与零售"三支线全部完成
--       才能接帝王酒(30073)"的结构冲突（零售数据源：Twinstar/Tauri/Wowpedia
--       三方一致的 Requires: 30047 + 30055 + 30172）：
--   * 30032{30032,30051}：做完寻找更好的大麦会锁死寻找活水 → 水线 30172 不可达
--   * 30029{30029,30049}：玩个小把戏（粮食线并列进料任务，Twinstar 系列证实
--     30029→30032）会锁死扛不动水 → 水线不可达
--   * 官方另有 30172.ExclusiveGroup=30047（粮/水终点互斥），已在 PART 3 中
--     随 -30073 组一并覆盖
-- 若不清理，-30073 each-from-all 门控永远无法满足，帝王酒成死任务。

UPDATE `quest_template_addon` SET `ExclusiveGroup` = 0 WHERE `ID` = 30032; -- 寻找更好的大麦
UPDATE `quest_template_addon` SET `ExclusiveGroup` = 0 WHERE `ID` = 30051; -- 寻找活水
UPDATE `quest_template_addon` SET `ExclusiveGroup` = 0 WHERE `ID` = 30049; -- 扛不动水


-- ############################################################################
-- # PART 5（原 04 号）：丽丽任务链门控
-- ############################################################################
--
-- 丽丽链零售结构：
--   29919 英雄所喝略同 ─┬─ 29944 擒兔先擒首（已有 prev）→ 29946 密径主母 ─┐
--                       └─ 29945 黄配红变橙色 → 29947 真假胡萝卜 ────────┤（并行支线）
--                           29948 窃贼本性(Thieves to the Core) ← 29944 ─┘
--   → 29949 遗产（主线脊 prev=29946，官方原样）→ 29950 丽丽的假日 → 29952 破碎的梦想
--   → 29951 浑水(Muddy Water)（遗产后开启，泥盏发放）
--   酒坊 assault：30074 敲门 → 30077 看那些木桶，伙计（并行）／30075 扫清道路 → 30078

-- ---- 5.A 黄配红变橙色 ← 英雄所喝略同 ----------------------------------------
-- Twinstar 29945: "Requires: Great Minds Drink Alike"，系列 1→2 真假胡萝卜
UPDATE `quest_template_addon` SET `PrevQuestID` = 29919 WHERE `ID` = 29945;

-- ---- 5.B 窃贼本性 29948 补 addon 行（官方/本地均无行，无门控） ---------------
-- Tauri 29948: "Requires: Leaders Among Breeders (29944)"，Start/End 泥盏 56474
-- （本地 creature_queststarter 已有 (56474,29948)，仅缺 addon 行）
-- 注意 next 置 0：不指向 29949，避免 OR 语义削弱遗产的主线脊门控（29949.prev=29946）
DELETE FROM `quest_template_addon` WHERE `ID` = 29948;
INSERT INTO `quest_template_addon`
  (`ID`, `MaxLevel`, `AllowableClasses`, `SourceSpellID`, `PrevQuestID`, `NextQuestID`,
   `ExclusiveGroup`, `RewardMailTemplateID`, `RewardMailDelay`, `RequiredSkillID`,
   `RequiredSkillPoints`, `RequiredMinRepFaction`, `RequiredMaxRepFaction`,
   `RequiredMinRepValue`, `RequiredMaxRepValue`, `ProvidedItemCount`, `SpecialFlags`, `ScriptName`)
VALUES
  (29948, 0, 0, 0, 29944, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');

-- ---- 5.C 看那些木桶，伙计 30077 补 addon 行（官方/本地均无行） ----------------
-- Tauri 30077: "Requires: Knocking on the Door (30074)"，Start/End 丽丽 56138
DELETE FROM `quest_template_addon` WHERE `ID` = 30077;
INSERT INTO `quest_template_addon`
  (`ID`, `MaxLevel`, `AllowableClasses`, `SourceSpellID`, `PrevQuestID`, `NextQuestID`,
   `ExclusiveGroup`, `RewardMailTemplateID`, `RewardMailDelay`, `RequiredSkillID`,
   `RequiredSkillPoints`, `RequiredMinRepFaction`, `RequiredMaxRepFaction`,
   `RequiredMinRepValue`, `RequiredMaxRepValue`, `ProvidedItemCount`, `SpecialFlags`, `ScriptName`)
VALUES
  (30077, 0, 0, 0, 30074, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');

-- ---- 5.D 浑水 29951 ← 遗产 ---------------------------------------------------
-- Wowpedia: Legacy → Li Li's Day Off & Muddy Water（并行）；Twinstar 29949 Open Quests 含 Muddy Water
-- 本地 addon 行存在但全零（无门控），发放者泥盏 56474
UPDATE `quest_template_addon` SET `PrevQuestID` = 29949 WHERE `ID` = 29951;
