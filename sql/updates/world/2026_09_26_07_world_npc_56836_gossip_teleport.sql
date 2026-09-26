-- NPC 56836 大贤者雷霆 (Elder Sage Thunder-Lei)
-- 新增对话选项 "我想返回青龙寺庭院。"，选择后传送到青龙寺庭院 (map 870, 992, -2449, 167)
-- 该 NPC 原为空白模板（npcflag=0 / 无菜单 / 无 AI），需一并启用 GOSSIP 与 SmartAI
-- 生效方式: 重启 worldserver（或 .reload creature_template + .reload smart_scripts 后重新 spawn 该 NPC）

SET @ENTRY := 56836;
-- 菜单 ID（13320-13400 范围内未被占用的 13325）
SET @MENU  := 13325;
SET @OPT   := 0;

-- 1. 模板: 开启 GOSSIP npcflag、SmartAI、绑定 gossip 菜单
UPDATE `creature_template` SET `npcflag`=1, `AIName`='SmartAI', `gossip_menu_id`=@MENU
WHERE `entry`=@ENTRY;

-- 2. gossip 菜单（TextID=1 通用问候语）
DELETE FROM `gossip_menu` WHERE `MenuID`=@MENU;
INSERT INTO `gossip_menu` (`MenuID`,`TextID`,`VerifiedBuild`)
VALUES (@MENU,1,0);

-- 3. 对话选项 "我想返回青龙寺庭院。"
DELETE FROM `gossip_menu_option` WHERE `MenuID`=@MENU AND `OptionID`=@OPT;
INSERT INTO `gossip_menu_option`
(`MenuID`,`OptionID`,`OptionIcon`,`OptionText`,`OptionBroadcastTextID`,`OptionType`,`OptionNpcflag`,`ActionMenuID`,`ActionPoiID`,`BoxCoded`,`BoxMoney`,`BoxText`,`BoxBroadcastTextID`,`VerifiedBuild`)
VALUES
(@MENU,@OPT,0,'我想返回青龙寺庭院。',0,1,1,0,0,0,0,'',0,0);

-- 4. SAI: 选择选项 (GOSSIP_SELECT menu=13325 option=0) → 传送对话者到庭院
--    朝向取该 NPC 刷新点朝向 4.39669，如需调整改 target_o 即可
DELETE FROM `smart_scripts` WHERE `entryorguid`=@ENTRY AND `source_type`=0;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(@ENTRY,0,0,0,62,0,100,0,@MENU,@OPT,0,0,0, 62,870,0,0,0,0,0, 7,0,0,0,0, 988.8,-2452.19,168.59,4.39669, 'Thunder-Lei (56836) - On gossip select option: teleport back to Temple of the Jade Serpent courtyard');
