-- Tipping the Balance (27431): missing Harrison gossip option and handler.
-- Functional conversation/credit fallback; does not recreate the statue cinematic.
-- Preserve On to Something's existing SmartAI event 0 on the same NPC.
UPDATE `creature_template` SET `AIName`='SmartAI'
WHERE `entry`=45296 AND `AIName`='' AND `ScriptName`='';
DELETE FROM `gossip_menu_option` WHERE `MenuID`=12037 AND `OptionID`=0;
INSERT INTO `gossip_menu_option`
(`MenuID`,`OptionID`,`OptionIcon`,`OptionText`,`OptionType`,`OptionNpcflag`)
VALUES (12037,0,0,'I am ready, Harrison. I will stay out of your way.',1,1);
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=15 AND `SourceGroup`=12037 AND `SourceEntry`=0;
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`Comment`)
VALUES (15,12037,0,9,0,27431,'Show Harrison option only for active Tipping the Balance');
DELETE FROM `smart_scripts` WHERE `entryorguid`=45296 AND `source_type`=0 AND `id` IN (1,2);
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_chance`,`event_param1`,`event_param2`,`action_type`,`action_param1`,`target_type`,`comment`) VALUES
(45296,0,1,2,62,100,12037,0,72,0,7,'Harrison - Tipping the Balance Gossip - Close Dialog'),
(45296,0,2,0,61,100,0,0,33,45742,7,'Harrison - Linked - Tipping the Balance Credit');
-- Also validate the selection itself, not only menu visibility.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=22 AND `SourceGroup`=2 AND `SourceEntry`=45296 AND `SourceId`=0;
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`Comment`)
VALUES (22,2,45296,0,9,0,27431,'Harrison gossip credit requires active Tipping the Balance');
