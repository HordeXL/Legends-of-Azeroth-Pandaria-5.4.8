-- ============================================================================
--  2026_09_28_01_world_xiao_hidden_master_chain.sql
--  晓（Xiao 56110，四风谷天禅院训练线）"寻找隐秘大师"任务链前置修复
--
--  问题（玩家截图：晓同时挂 5 个任务，全部无前置）：
--    30086 寻找隐秘大师（The Search for the Hidden Master，链根，听晓一伙人聊天）
--      ├─ 29871 聪明的阿西约（Clever Ashyo，联盟/部落通用）
--      ├─ 29872 林·柔掌（Lin Tenderpaw）
--      ├─ 29873 肯肯（Ken-Ken）
--      ├─ 29874 康·棘杖（联盟版，AllowableRaces=18875469）
--      └─ 29875 康·棘杖（部落版，AllowableRaces=33555378）
--    四个"寻找同伴"任务零售端均要求先完成 30086（晓的一伙人此时还聚在
--    楼上未散去，听完对话后各自出发，玩家才能去各处找到他们）。
--
--  数据依据：
--    * Tauri (mop-shoot.tauri.hu) 明确列出 Requires 30086：29872 / 29874 / 29875
--      （29871 / 29873 在 Tauri 无 Quick Facts 数据块，按同一枢纽同一模式补齐）
--    * 官方 5.4.8 world dump 与本库一致（仅 29872 有 addon 行）——零售前置
--      存于客户端 DB2，world dump 无该数据（与陈·风暴烈酒任务线结论相同）
--    * 下游链完好无需改动：29577←29871、29981←29872(NextQuestID 已有)、
--      30079←29873，29577→29581、30079→30081 走 RewardNextQuest
--
--  修复：为 29871/29873/29874/29875 补 addon 行、29872 更新 PrevQuestID，
--        全部指向上游 30086。幂等：INSERT 前 DELETE。
-- ============================================================================

-- ---- 1. 29872 林·柔掌：已有 addon 行，仅补 PrevQuestID（保留 NextQuestID=29981）
UPDATE `quest_template_addon` SET `PrevQuestID` = 30086 WHERE `ID` = 29872; -- 林·柔掌 ← 寻找隐秘大师

-- ---- 2. 补缺失的 4 行 addon -------------------------------------------------
DELETE FROM `quest_template_addon` WHERE `ID` IN (29871, 29873, 29874, 29875);
INSERT INTO `quest_template_addon`
    (`ID`, `MaxLevel`, `AllowableClasses`, `SourceSpellID`, `PrevQuestID`, `NextQuestID`, `ExclusiveGroup`,
     `RewardMailTemplateID`, `RewardMailDelay`, `RequiredSkillID`, `RequiredSkillPoints`,
     `RequiredMinRepFaction`, `RequiredMaxRepFaction`, `RequiredMinRepValue`, `RequiredMaxRepValue`,
     `ProvidedItemCount`, `SpecialFlags`, `ScriptName`) VALUES
(29871, 0, 0, 0, 30086, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''), -- 聪明的阿西约 ← 寻找隐秘大师
(29873, 0, 0, 0, 30086, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''), -- 肯肯 ← 寻找隐秘大师
(29874, 0, 0, 0, 30086, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''), -- 康·棘杖(联盟) ← 寻找隐秘大师
(29875, 0, 0, 0, 30086, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''); -- 康·棘杖(部落) ← 寻找隐秘大师
