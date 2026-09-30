-- 2026_09_30_01_world_quest_29891_chain.sql
-- 修复任务 29891「效力」(Potency) 所在的游学者周卓/安度因任务链：
--
-- 官方链条 (Wowpedia):
--   29888 寻找游学者 -> 29889 借来的酒 -> 31130 拜访游学者
--     -> [并列] 29891 效力 + 29892 身体 + 29893 色彩
--       -> 29890 找到中心 (官方 requires Potency)
--         -> [并列] 29898 神圣之水 + 29899 安息 + 29900 古老的传说
--           -> 29901 安度因的决定
--
-- 问题 1: 29891/29892/29893 在 quest_template_addon 无行（无前置链接），
--         31130.RewardNextQuest = 0，导致链断。
-- 问题 2: 29890 无 PrevQuestID。
-- 问题 3: 29890 的目标 NPC 56269（周卓·追梦亭冥想台）无 spawn，任务无法完成。
--         POI 定位 (-632,-2365)，冥想蜡烛/安神香 (z≈22.87) 证实为追梦亭冥想圈。

-- ---------- 1. 补任务链 ----------
DELETE FROM `quest_template_addon` WHERE `ID` IN (29891, 29892, 29893, 29890);
INSERT INTO `quest_template_addon`
  (`ID`, `MaxLevel`, `AllowableClasses`, `SourceSpellID`, `PrevQuestID`, `NextQuestID`, `ExclusiveGroup`, `SpecialFlags`)
VALUES
  (29891, 0, 0, 0, 31130, 0, 0, 0),
  (29892, 0, 0, 0, 31130, 0, 0, 0),
  (29893, 0, 0, 0, 31130, 0, 0, 0),
  (29890, 0, 0, 0, 29891, 0, 0, 0);

-- 31130 拜访游学者 -> 引出并列三任务
UPDATE `quest_template` SET `RewardNextQuest` = 29891 WHERE `ID` = 31130 AND `RewardNextQuest` = 0;

-- ---------- 2. 补 56269（周卓·追梦亭）spawn ----------
-- 位置：冥想蜡烛圈中心 (-623.3, -2358.5, 22.87)，map 870, area 5940
DELETE FROM `creature` WHERE `id` = 56269;
INSERT INTO `creature`
  (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `modelid`, `equipment_id`,
   `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `spawntimesecs_max`,
   `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`,
   `npcflag`, `npcflag2`, `unit_flags`, `unit_flags2`, `dynamicflags`, `ScriptName`, `walk_mode`, `VerifiedBuild`)
VALUES
  (4002002, 56269, 870, 5785, 5940, 1, 1, 0, 0,
   -623.3, -2358.5, 22.87, 2.4, 300, 300,
   0, 0, 1, 0, 0,
   2, 0, 0, 0, 0, '', 0, 18414);
