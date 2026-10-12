-- 2026_10_12_05_world_quest_29950_new_cifera_relocate.sql
-- 29950 新希菲拉触发点位置修正（实测反馈：到达不计数 + POI 无指引）
--
-- 根因：初版把新希菲拉 credit 触发挂在了 PRK bunny guid 513945 (182,272) 上——
-- 该点实为半山西侧黑眉商队路边（Mei/Rin/Lo Blackbrow 商队营地），不是新希菲拉村！
-- 错选原因：误将阿西约 56113 的第二静态刷点(200,276)当作村址，实际那是去净水池
-- 途中的商队点（阿西约 29577 会跑到净水池边，两处都是他）。
-- 真正的新希菲拉村 = 张跃 56802 (364.7,331.2) / 村民版阿西约 57204 (365.7,333.2) 所在
-- 任务枢纽（wiki：Ashyo 与 Zhang Yue 都在 New Cifera；29581 Snap Judgment 由张跃发放）。
-- POI blob2 (198,279) 亦不可靠（本库 quest_poi_points 已知截断偏差）。
--
-- 修正：
--   1) 删除错误 bunny 513945 的 SAI，删除该 bunny 本体（它无其它用途前先确认——
--      保守起见保留本体只删 SAI？否：该 bunny 是官方数据，保留本体、只迁移脚本）；
--   2) 在村中心 (365.5, 332.2, z 189.5) 新增 PRK bunny（entry 41200），
--      GUID 级 OOC_LOS → QUESTTAKEN 29950 → credit 56547 + 丽丽台词组 2/3。
--
-- 已应用 world 库；生效：重启或 .reload smart_scripts + 重刷新增 bunny。

-- ===== 1. 移除错误位置的触发 =====
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = -513945;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = -513945;

-- ===== 2. 新增村内 bunny（guid 沿用 4001xxx 专用段避免冲突） =====
DELETE FROM `creature` WHERE `guid` = 4003310;
INSERT INTO `creature` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `VerifiedBuild`) VALUES
(4003310, 41200, 870, 1, 1, 365.5, 332.2, 189.5, 4.95, 300, 18414);

-- ===== 3. 触发 SAI（同丝纱/瀑布模式） =====
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = -4003310;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(-4003310, 0, 0, 1, 10, 0, 100, 0, 1, 25, 15, 30, 1, 33, 56547, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'New Cifera - LOS Player With Q29950 - Credit 56547'),
(-4003310, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 19, 56549, 20, 0, 0, 0, 0, 0, 0, 'New Cifera - Link - Li Li Say G2'),
(-4003310, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 19, 56549, 20, 0, 0, 0, 0, 0, 0, 'New Cifera - Link - Li Li Say G3');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceEntry` = -4003310;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(22, 1, -4003310, 0, 0, 9, 0, 29950, 0, 0, 0, 0, 0, '', 'New Cifera LOS credit only when quest 29950 in progress');
