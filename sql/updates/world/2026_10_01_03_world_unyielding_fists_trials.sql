-- Unyielding Fists: Trial of Bamboo/Wood/Stone (29984/29987/29989)
--
-- Master Bruised Paw has gossip menu 13301, but the three retail gossip
-- options and their quest conditions are absent.  The original trial also
-- relies on alternate-power handling which this core does not implement
-- (SPELL_AURA_ENABLE_ALT_POWER is NYI).  Preserve the retail interaction:
-- selecting the appropriate option summons that trial's stack, and each
-- spell-click on the stack casts the client credit/strike spell 106697 as
-- the player.  The quest objective itself enforces 3/4/5 successful strikes.

START TRANSACTION;

UPDATE `creature_template`
SET `AIName`='SmartAI'
WHERE `entry`=56714 AND `ScriptName`='';

UPDATE `creature_template`
SET `npcflag`=`npcflag` | 16777216, `faction`=35
WHERE `entry` IN (56797,56800,56801) AND `ScriptName`='';

DELETE FROM `gossip_menu_option`
WHERE `MenuID`=13301 AND `OptionID` IN (0,1,2);

INSERT INTO `gossip_menu_option`
(`MenuID`,`OptionID`,`OptionIcon`,`OptionText`,`OptionBroadcastTextID`,
 `OptionType`,`OptionNpcflag`,`ActionMenuID`,`ActionPoiID`,`BoxCoded`,
 `BoxMoney`,`BoxText`,`BoxBroadcastTextID`,`VerifiedBuild`) VALUES
(13301,0,0,'I\'m ready for the trial of bamboo.',55821,1,1,0,0,0,0,NULL,0,18414),
(13301,1,0,'My fists are ready. Bring on the trial of wood.',55822,1,1,0,0,0,0,NULL,0,18414),
(13301,2,0,'I\'ve done all that you\'ve asked of me. I\'m ready for the trial of stone.',55823,1,1,0,0,0,0,NULL,0,18414);

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId`=15 AND `SourceGroup`=13301
  AND `SourceEntry` IN (0,1,2);

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
 `ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,
 `ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`) VALUES
(15,13301,0,0,0,9,0,29984,0,0,0,0,0,'','Master Bruised Paw - Show Trial of Bamboo while quest 29984 is active'),
(15,13301,1,0,0,9,0,29987,0,0,0,0,0,'','Master Bruised Paw - Show Trial of Wood while quest 29987 is active'),
(15,13301,2,0,0,9,0,29989,0,0,0,0,0,'','Master Bruised Paw - Show Trial of Stone while quest 29989 is active');

DELETE FROM `smart_scripts`
WHERE `entryorguid`=56714 AND `source_type`=0 AND `id` BETWEEN 0 AND 5;

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,
 `event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,
 `event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,
 `action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,
 `target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,
 `target_y`,`target_z`,`target_o`,`comment`) VALUES
(56714,0,0,1,62,0,100,0,13301,0,0,0,0,85,106911,2,0,0,0,0,7,0,0,0,0,0,0,0,0,'Master Bruised Paw - Trial of Bamboo selected - Player summons bamboo stack'),
(56714,0,1,0,61,0,100,0,0,0,0,0,0,72,0,0,0,0,0,0,7,0,0,0,0,0,0,0,0,'Master Bruised Paw - Trial of Bamboo selected - Close gossip'),
(56714,0,2,3,62,0,100,0,13301,1,0,0,0,85,106912,2,0,0,0,0,7,0,0,0,0,0,0,0,0,'Master Bruised Paw - Trial of Wood selected - Player summons wooden stack'),
(56714,0,3,0,61,0,100,0,0,0,0,0,0,72,0,0,0,0,0,0,7,0,0,0,0,0,0,0,0,'Master Bruised Paw - Trial of Wood selected - Close gossip'),
(56714,0,4,5,62,0,100,0,13301,2,0,0,0,85,106913,2,0,0,0,0,7,0,0,0,0,0,0,0,0,'Master Bruised Paw - Trial of Stone selected - Player summons stone stack'),
(56714,0,5,0,61,0,100,0,0,0,0,0,0,72,0,0,0,0,0,0,7,0,0,0,0,0,0,0,0,'Master Bruised Paw - Trial of Stone selected - Close gossip');

DELETE FROM `npc_spellclick_spells`
WHERE `npc_entry` IN (56797,56800,56801) AND `spell_id`=106697;

INSERT INTO `npc_spellclick_spells`
(`npc_entry`,`spell_id`,`cast_flags`,`user_type`) VALUES
(56797,106697,1,0),
(56800,106697,1,0),
(56801,106697,1,0);

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId`=18
  AND `SourceGroup` IN (56797,56800,56801) AND `SourceEntry`=106697;

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
 `ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,
 `ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`) VALUES
(18,56797,106697,0,0,9,0,29984,0,0,0,0,0,'','Bamboo stack - Click requires Trial of Bamboo active'),
(18,56800,106697,0,0,9,0,29987,0,0,0,0,0,'','Wood stack - Click requires Trial of Wood active'),
(18,56801,106697,0,0,9,0,29989,0,0,0,0,0,'','Stone stack - Click requires Trial of Stone active');

COMMIT;
