-- ============================================================
-- 金莲教开场叙事链 (30630-30649) 修复
-- 2026-09-30 | 修复内容:
--   1. 补 6 个关键 NPC spawn (Zhi/Lao/He/Zhao-Jin×2/Dagou)
--   2. 补 8 个韶天先驱 spawn (30633 击杀目标, 原先零 spawn)
--   3. 补 16 个任务的发放/交付行 (creature_queststarter/ender)
--   4. 补链: 30638 三线汇聚 (X=-30638, 同 30073 帝王酒模式)
--   5. 补声望门槛: 30639 尊敬(9000), 30640-42 崇敬(21000),
--      30643-46 崇拜(42000), 阵营 1269 金莲教
--   (核心 RequiredMinRepValue = 声望点数, Player.cpp SatisfyQuestReputation)
-- 数据源: Wowhead mop-classic 逐任务 Start/End + Wowpedia 进度块 + huijiwiki
-- 未修 (记录): 30630 (beta 废弃, live 链条从 30631/30649 开始),
--   30648 (目标是开发用 Bunny 59692, 非 live 任务),
--   30634 埋桶信用 60011 与 Lao 潜行护送需 SAI (任务可接可交, 简化处理)
-- ============================================================

USE `world`;

-- ---------- A. 补 spawn ----------
-- A1. Zhi the Harmonious 和谐者智 @ 鎏金亭营地 (参照 Sun 71480/Leven 59332, z≈420)
--     同时救活 31511「A Witness to History」的交付行 (官方交付者即 59905)
DELETE FROM `creature` WHERE `guid` IN (4002401);
INSERT INTO `creature`
  (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
VALUES
  (4002401,59905,870,5840,6036,1,1,0,0,1219.0,1042.0,420.0,2.30,300,300,0,0,0,0,0,3,0,0,0,0,'',1,0);

-- A2. Lao Softfoot 劳·软足 @ 遗迹高地洞口 (30634 POI blob4: 1571,1620; 参照 Shao-Tien Fist z≈389)
DELETE FROM `creature` WHERE `guid` IN (4002402);
INSERT INTO `creature`
  (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
VALUES
  (4002402,60002,870,5840,6053,1,1,0,0,1571.0,1620.0,389.0,5.20,300,300,0,0,0,0,0,1,0,0,0,0,'',1,0);

-- A3. He Softfoot 何·蹑足(郭莱古厅变体) @ 古厅西侧大厅入口 (30639 POI; 参照 Stone Guardian 59973 z≈456)
DELETE FROM `creature` WHERE `guid` IN (4002403);
INSERT INTO `creature`
  (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
VALUES
  (4002403,64647,870,5840,6149,1,1,0,0,1652.0,1897.0,456.0,4.10,300,300,0,0,0,0,0,0,0,0,0,0,'',1,0);

-- A4. Zhao-Jin the Bloodletter (64663, 30639 雕像大厅信用) @ 古厅
DELETE FROM `creature` WHERE `guid` IN (4002404);
INSERT INTO `creature`
  (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
VALUES
  (4002404,64663,870,5840,6149,1,1,0,0,1630.0,1960.0,458.0,1.05,300,300,0,0,0,0,0,0,0,0,0,0,'',1,0);

-- A5. Dagou 大狗 (30637 目标) @ 古厅王座 (参照 Generic Bunny 触发点 1608,1935 z≈437)
DELETE FROM `creature` WHERE `guid` IN (4002405);
INSERT INTO `creature`
  (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
VALUES
  (4002405,59977,870,5840,6149,1,1,0,0,1615.0,1938.0,448.0,0.80,300,300,0,0,0,0,0,0,0,0,0,0,'',1,0);

-- A6. Zhao-Jin the Bloodletter (60273, 30646 最终决战目标) @ 古厅王座旁
DELETE FROM `creature` WHERE `guid` IN (4002406);
INSERT INTO `creature`
  (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
VALUES
  (4002406,60273,870,5840,6149,1,1,0,0,1612.0,1930.0,448.0,2.60,300,300,0,0,0,0,0,0,0,0,0,0,'',1,0);

-- A7. Shao-Tien Precursor 韶天先驱 ×8 (30633 击杀目标, 原先零 spawn)
--     沿郭莱遗迹北上路线分布 (参照 Shao-Tien Fist 65134 群 z 381-394)
DELETE FROM `creature` WHERE `guid` BETWEEN 4002407 AND 4002414;
INSERT INTO `creature`
  (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
VALUES
  (4002407,59914,870,5840,6053,1,1,0,0,1560.0,1627.0,389.0,0.00,300,300,5,0,0,0,1,0,0,0,0,0,'',1,0),
  (4002408,59914,870,5840,6053,1,1,0,0,1573.0,1649.0,389.0,0.00,300,300,5,0,0,0,1,0,0,0,0,0,'',1,0),
  (4002409,59914,870,5840,6053,1,1,0,0,1597.0,1658.0,394.0,0.00,300,300,5,0,0,0,1,0,0,0,0,0,'',1,0),
  (4002410,59914,870,5840,6053,1,1,0,0,1538.0,1627.0,381.0,0.00,300,300,5,0,0,0,1,0,0,0,0,0,'',1,0),
  (4002411,59914,870,5840,6053,1,1,0,0,1545.0,1640.0,385.0,0.00,300,300,5,0,0,0,1,0,0,0,0,0,'',1,0),
  (4002412,59914,870,5840,6053,1,1,0,0,1585.0,1636.0,390.0,0.00,300,300,5,0,0,0,1,0,0,0,0,0,'',1,0),
  (4002413,59914,870,5840,6053,1,1,0,0,1552.0,1665.0,388.0,0.00,300,300,5,0,0,0,1,0,0,0,0,0,'',1,0),
  (4002414,59914,870,5840,6053,1,1,0,0,1525.0,1615.0,383.0,0.00,300,300,5,0,0,0,1,0,0,0,0,0,'',1,0);

-- ---------- B. 补发放/交付行 ----------
-- 发放者 entry 选择: 全部使用有 spawn 的 entry
--   Sun=59337(鎏金亭×2), Leven=59332(鎏金亭), Anji=58465(郭莱遗迹营),
--   Kun=58920(郭莱遗迹营/卫戍营), Zhi=59905(新增), Sinan=59906(郭莱遗迹营)
DELETE FROM `creature_queststarter` WHERE `quest` IN (30631,30632,30633,30634,30635,30636,30654,30638,30639,30640,30641,30642,30643,30644,30645,30646,30649);
DELETE FROM `creature_questender`  WHERE `quest` IN (30631,30632,30633,30634,30635,30636,30637,30654,30638,30639,30640,30641,30642,30643,30644,30645,30646,30649);

INSERT INTO `creature_queststarter` (`quest`,`id`) VALUES
  -- 30631 七星殿 (联盟): 孙·柔心 (Wowhead mop-classic: Start/End Sun Tenderheart)
  (30631,59337),
  -- 30632 郭莱遗迹: 莱文发放 → 安济交付 (Wowhead: Start Leven / End Anji; huijiwiki 坐标 56.4,43.4 → 34.0,38.2)
  (30632,59332),
  -- 30633 消灭斥候: 安济 (Wowhead: Start/End Anji)
  (30633,58465),
  -- 30634 堵住洞口: 奎·秋光 (Wowpedia: Start/End Kun Autumnlight 33.7,38.4; StartItem 80484 并存)
  (30634,58920),
  -- 30635 杀死魁麟 / 30636 力量之石: 安济 (Wowhead: Start/End Anji)
  (30635,58465),
  (30636,58465),
  -- 30654 郭莱古厅 (mop-classic 版): 安济 (Wowhead mop-classic: Start/End Anji)
  (30654,58465),
  -- 30638 引路·猝不及防: 安济发放 → 莱文交付 (Wowpedia: Start Anji / End Leven at Golden Pagoda)
  (30638,58465),
  -- 30639 郭莱的秘密: 莱文 (Wowhead/huijiwiki/damijing: Start/End Leven)
  (30639,59332),
  -- 30640/30641/30642 雷电之王三件套: 智先生 (Wowhead: Start/End Zhi the Harmonious)
  (30640,59905),
  (30641,59905),
  (30642,59905),
  -- 30643 魔古族的口信: 莱文发放 → 智先生交付 (Wowpedia: Start Leven / End Zhi)
  (30643,59332),
  -- 30644 逝者已矣: 智先生发放 → 孙·柔心交付 (玩家评论: 交付给鎏金亭的孙·柔心)
  (30644,59905),
  -- 30645 三人之力: 孙·柔心发放 → 梦想家思南交付 (Wowhead: Start Sun / End Sinan)
  (30645,59337),
  -- 30646 最后的力量: 思南发放 → 安济交付 (Wowhead: Start Sinan / End Anji)
  (30646,59906),
  -- 30649 双月殿 (部落): 孙·柔心 (Wowhead mop-classic: Start/End Sun; 目标 4 NPC 全部有 spawn)
  (30649,59337);

INSERT INTO `creature_questender` (`quest`,`id`) VALUES
  (30631,59337),(30631,64031),          -- 交付: 孙·柔心 + 善良的夏瑞 (Wowhead 双交付)
  (30632,58465),
  (30633,58465),
  (30634,58920),
  (30635,58465),
  (30636,58465),
  (30637,58465),                        -- 30637 为古厅自动触发(discovery), 仅补交付
  (30654,58465),
  (30638,59332),
  (30639,59332),
  (30640,59905),
  (30641,59905),
  (30642,59905),
  (30643,59905),
  (30644,59337),
  (30645,59906),
  (30646,58465),
  (30649,59337),(30649,64007);          -- 交付: 孙·柔心 + 慈悲的翁 (Wowhead 双交付)

-- ---------- C. 补链与声望门槛 (quest_template_addon) ----------
-- C1. 30638 猝不及防: 官方要求 30635/30636/30637 三线全部完成
--     (Wowpedia Previous 三项 + db.pandawow 条件显示) → 同「帝王酒」each-from-all 模式
UPDATE `quest_template_addon` SET `ExclusiveGroup` = -30638 WHERE `ID` = 30635;
INSERT INTO `quest_template_addon`
  (`ID`,`MaxLevel`,`AllowableClasses`,`SourceSpellID`,`PrevQuestID`,`NextQuestID`,`ExclusiveGroup`,`RewardMailTemplateID`,`RewardMailDelay`,`RequiredSkillID`,`RequiredSkillPoints`,`RequiredMinRepFaction`,`RequiredMaxRepFaction`,`RequiredMinRepValue`,`RequiredMaxRepValue`,`ProvidedItemCount`,`SpecialFlags`,`ScriptName`)
VALUES
  (30636,0,0,0,0,0,-30638,0,0,0,0,0,0,0,0,0,0,''),
  (30637,0,0,0,0,0,-30638,0,0,0,0,0,0,0,0,0,0,''),
  (30638,0,0,0,30635,0,-30638,0,0,0,0,0,0,0,0,0,0,'');

-- C2. 声望门槛 (Wowpedia 进度块: At honored / At revered / At exalted)
--     核心按声望点数比较: 尊敬=9000, 崇敬=21000, 崇拜=42000; 金莲教=1269
INSERT INTO `quest_template_addon`
  (`ID`,`MaxLevel`,`AllowableClasses`,`SourceSpellID`,`PrevQuestID`,`NextQuestID`,`ExclusiveGroup`,`RewardMailTemplateID`,`RewardMailDelay`,`RequiredSkillID`,`RequiredSkillPoints`,`RequiredMinRepFaction`,`RequiredMaxRepFaction`,`RequiredMinRepValue`,`RequiredMaxRepValue`,`ProvidedItemCount`,`SpecialFlags`,`ScriptName`)
VALUES
  (30639,0,0,0,0,0,0,0,0,0,0,1269,0,9000,0,0,0,''),
  (30640,0,0,0,0,0,0,0,0,0,0,1269,0,21000,0,0,0,''),
  (30641,0,0,0,0,0,0,0,0,0,0,1269,0,21000,0,0,0,''),
  (30642,0,0,0,0,0,0,0,0,0,0,1269,0,21000,0,0,0,''),
  (30643,0,0,0,0,0,0,0,0,0,0,1269,0,42000,0,0,0,''),
  (30644,0,0,0,0,0,0,0,0,0,0,1269,0,42000,0,0,0,''),
  (30645,0,0,0,0,0,0,0,0,0,0,1269,0,42000,0,0,0,'');
UPDATE `quest_template_addon`
  SET `RequiredMinRepFaction` = 1269, `RequiredMinRepValue` = 42000
  WHERE `ID` = 30646;                    -- 30646 已有行 (PrevQuestID=30645), 只补声望
