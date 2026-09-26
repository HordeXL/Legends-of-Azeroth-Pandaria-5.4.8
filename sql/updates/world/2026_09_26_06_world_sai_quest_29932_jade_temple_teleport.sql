-- Quest 29932 "The Temple of the Jade Serpent" (青龙寺) - 双分支方案
-- NPC: 大贤者易冈 (Elder Sage Wind-Yi, 57242)，gossip 菜单 13324
--
-- 分支 A（已领取任务 29932）：与 57242 对话 → 完成 credit(57290) → 播放场景 66
--   场景结束后由 C++ SceneScript 'scene_jade_temple_teleport' 传送（scene_template.ScriptName 绑定）
-- 分支 B（未领取任务）：gossip 选项 "送我到青龙寺庭院。" → 选择后直接传送到庭院
--
-- 生效方式: .reload smart_scripts + .reload conditions (或重启 worldserver)

SET @ENTRY := 57242;
SET @MENU  := 13324;
-- gossip 选项 OptionID（菜单当前无其他选项）
SET @OPT   := 0;

-- ==================== 分支 A：任务对话 → 场景 ====================

-- 清理旧版本行（旧方案的场景 244 / 立即传送行）
DELETE FROM `smart_scripts` WHERE `entryorguid`=@ENTRY AND `source_type`=0 AND `id` IN (1,2,3);

-- id0 (GOSSIP_HELLO, 已有): credit 改为仅作用于对话者 (ACTION_INVOKER=7)，并链到 id1
UPDATE `smart_scripts` SET `link`=1, `target_type`=7
WHERE `entryorguid`=@ENTRY AND `source_type`=0 AND `id`=0 AND `event_type`=64;

-- id1: 链式动作 - 播放场景 66 (apply=1)，目标 = 对话者
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(@ENTRY,0,1,0,61,0,100,0,0,0,0,0,0, 201,66,1,0,0,0,0, 7,0,0,0,0, 0,0,0,0, 'Wind-Yi (57242) - On gossip hello linked: play Temple of the Jade Serpent scene 66 (teleport on scene complete via scene_jade_temple_teleport)');

-- id0 条件：任务 29932 处于 进行中(8) 或 已完成未交(2) 状态才触发
-- 注意：本核心 SMART_EVENT 条件查找键为 SourceEntry = 事件id + 1（ConditionMgr.cpp:1116）
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=22 AND `SourceGroup`=@ENTRY AND `SourceId`=0 AND `SourceEntry`=1;
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,`ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`)
VALUES
(22,@ENTRY,1,0,0,47,0,29932,10,0,0,0,0,'','Wind-Yi (57242) gossip hello (event 0): only for quest 29932 in progress (8) or complete (2)');

-- ==================== 分支 B：gossip 选项直接传送 ====================

-- 新增 gossip 选项 "送我到青龙寺庭院。"
DELETE FROM `gossip_menu_option` WHERE `MenuID`=@MENU AND `OptionID`=@OPT;
INSERT INTO `gossip_menu_option`
(`MenuID`,`OptionID`,`OptionIcon`,`OptionText`,`OptionBroadcastTextID`,`OptionType`,`OptionNpcflag`,`ActionMenuID`,`ActionPoiID`,`BoxCoded`,`BoxMoney`,`BoxText`,`BoxBroadcastTextID`,`VerifiedBuild`)
VALUES
(@MENU,@OPT,0,'送我到青龙寺庭院。',0,1,1,0,0,0,0,'',0,0);

-- 选项可见性条件：任务 29932 不处于 进行中/已完成未交 状态时可见（负条件）
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=15 AND `SourceGroup`=@MENU AND `SourceEntry`=@OPT;
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,`ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`)
VALUES
(15,@MENU,@OPT,0,0,47,0,29932,10,0,1,0,0,'','Wind-Yi (57242) gossip option: hidden while quest 29932 in progress or complete');

-- SAI：选择该选项 (GOSSIP_SELECT menu=13324 action=OptionID) → 直接传送到青龙寺庭院
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(@ENTRY,0,3,0,62,0,100,0,@MENU,@OPT,0,0,0, 62,870,0,0,0,0,0, 7,0,0,0,0, 918.0,-2597.0,181.0,-1.177, 'Wind-Yi (57242) - On gossip select option: teleport into Temple of the Jade Serpent grounds (no scene)');

-- ==================== 场景结束传送：绑定 C++ SceneScript ====================
UPDATE `scene_template` SET `ScriptName`='scene_jade_temple_teleport' WHERE `SceneId`=66;
