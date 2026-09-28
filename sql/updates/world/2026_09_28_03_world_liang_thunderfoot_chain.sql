-- ============================================================================
--  2026_09_28_03_world_liang_thunderfoot_chain.sql
--  梁·雷脚（56205）任务链零售前置修复
--
--  零售链（Tauri/Twinstar）：
--    29912 热心的范姬小姐（庞给予，梁交付）
--      └─ 29914 送回猪圈        ← Tauri 明确 Requires 29912
--    29913 爱吃的肉             ← 零售无前置（Quick Facts 无 Requires 行），立即可接
--    29913 + 29914 ──(ExclusiveGroup -29913 each-from-all)──▶ 29915 邻居的义务
--
--  缺口：29914 缺前置 29912（官方 dump 同样缺失，零售前置在客户端 DB2）。
--  29915 的双支全完成门控由 29913/29914 的 NextQuestID=29915 + 负 ExclusiveGroup
--  机制（Player.cpp SatisfyQuestDependentPreviousQuests each-from-all 分支）实现，
--  现有数据已正确，无需改动。
-- ============================================================================

UPDATE `quest_template_addon` SET `PrevQuestID` = 29912 WHERE `ID` = 29914;
