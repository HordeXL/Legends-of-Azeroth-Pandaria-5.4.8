-- ============================================================
-- 昆莱山审计修复（2026-09-30_05）
-- 问题：红鹤寺剧情线（实际位于卡桑琅丛林边界，QuestSortID=6134）
--       的 2 个关键 NPC 无 spawn，导致 5 个任务无法交付/接取：
--   1. 30268 昏热症 (The Murksweats)  发放+交付 = 安度因 58609（无 spawn）
--   2. 30271 敬畏煞 / 30272 击退大雨 / 30695 前进之路
--      交付 = 安度因 59608（无 spawn）
--   3. 30273 红鹤寺内 开启 = 安度因 59608（无 spawn）
--   4. 30129 魔古的阴谋 交付 = 康·荆棘杖 58206（无 spawn）
--   5. 30128 青春之池 发放 = 康·荆棘杖 58206（无 spawn）
--
-- 依据：
--   - quest_poi_points：30128 POI blob0 = (-1122, 516)（青春之池起点，
--     旁有 NPC 纳雷克 55597 @ z≈59.4）
--   - 官方剧情（Wowpedia）：完成第一组任务后"安度因走到坐着的科罗身边，
--     两人一起发放任务"，故 59608 放在科罗 59138 旁边；
--     初始安度因 58609 放在难民营地（供给者安 67183 附近）
--   - 跳过 59189（30271 冗余发放者，59188 已覆盖）与 58814
--     （30351 冗余交付者，56114 已覆盖），参照翡翠林审计惯例
-- ============================================================

USE `world`;

SET @GUID_KANG      := 4002101; -- 58206 康·荆棘杖（青春之池）
SET @GUID_ANDUIN_1  := 4002102; -- 58609 安度因（难民营地初始位）
SET @GUID_ANDUIN_2  := 4002103; -- 59608 安度因（科罗旁交付位）

DELETE FROM `creature` WHERE `guid` IN (@GUID_KANG, @GUID_ANDUIN_1, @GUID_ANDUIN_2);

INSERT INTO `creature`
  (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `phaseId`, `phaseGroup`,
   `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
   `spawntimesecs`, `spawntimesecs_max`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`,
   `MovementType`, `npcflag`, `npcflag2`, `unit_flags`, `unit_flags2`, `dynamicflags`, `ScriptName`, `walk_mode`, `VerifiedBuild`)
VALUES
-- 康·荆棘杖：青春之池起点（POI blob0 旁，纳雷克 55597 同高度）
(@GUID_KANG, 58206, 870, 6134, 6011, 1, 1, 0, 0,
 0, 0, -1122.00, 516.00, 59.40, 5.35,
 300, 300, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, '', 0, 0),
-- 安度因（初始）：难民营地，供给者安 67183 旁
(@GUID_ANDUIN_1, 58609, 870, 6134, 6049, 1, 1, 0, 0,
 0, 0, -1180.00, 1034.00, 21.97, 2.40,
 300, 300, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, '', 0, 0),
-- 安度因（交付位）：科罗 59138 (-1162.95, 1045.74) 旁，剧情"走到科罗身边"
(@GUID_ANDUIN_2, 59608, 870, 6134, 6049, 1, 1, 0, 0,
 0, 0, -1160.50, 1047.50, 21.97, 3.60,
 300, 300, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, '', 0, 0);
