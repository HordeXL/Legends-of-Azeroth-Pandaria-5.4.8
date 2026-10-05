-- Unsafe Passage (30269): bind Koro's gossip option to the scripted escort.
-- The escort follows the existing 58547 waypoint path, stops for two waves of
-- two Riverblade Bloodletters, and grants objective credit near the refuge.

START TRANSACTION;

DELETE FROM `gossip_menu_option`
WHERE `MenuID` IN (58547,13468) AND `OptionID`=0;

INSERT INTO `gossip_menu_option`
(`MenuID`,`OptionID`,`OptionIcon`,`OptionText`,`OptionBroadcastTextID`,
 `OptionType`,`OptionNpcflag`,`ActionMenuID`,`ActionPoiID`,`BoxCoded`,
 `BoxMoney`,`BoxText`,`BoxBroadcastTextID`,`VerifiedBuild`) VALUES
(13468,0,0,'I\'m ready, Koro.',57913,1,1,0,0,0,0,NULL,0,18414);

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId`=15
  AND `SourceGroup` IN (58547,13468) AND `SourceEntry`=0;

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
 `ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,
 `ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`) VALUES
(15,13468,0,0,0,9,0,30269,0,0,0,0,0,'',
 'Koro Mistwalker - Show escort response while Unsafe Passage is active');

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId`=22 AND `SourceEntry`=58547;

DELETE FROM `smart_scripts`
WHERE `entryorguid`=58547 AND `source_type`=0;

-- The two old world spawns represented only the first ambush and could be
-- killed before Koro arrived. Both waves are now owned by the escort script.
DELETE `creature_addon`
FROM `creature_addon`
INNER JOIN `creature` ON `creature`.`guid`=`creature_addon`.`guid`
WHERE `creature`.`guid` IN (518086,518087) AND `creature`.`id`=58981;

DELETE FROM `creature`
WHERE `guid` IN (518086,518087) AND `id`=58981;

UPDATE `creature_template`
SET `AIName`='', `ScriptName`='npc_koro_mistwalker_unsafe_passage'
WHERE `entry`=58547;

COMMIT;
