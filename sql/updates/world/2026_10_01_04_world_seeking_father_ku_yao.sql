-- Seeking Father (30933): restore Sentinel Ku-Yao's location and conversation.
--
-- The objective entry (61694) was spawned at Shado-Pan Garrison while the
-- non-objective rescue/summon entry (65342) was spawned in the Feeding Pits.
-- Swap those two exact spawns.  The final gossip choice casts Blizzard's
-- Seeking Father spell 127918 as the player; the spell grants credit for
-- 61694 and summons the rescue version of Ku-Yao.

START TRANSACTION;

UPDATE `creature`
SET `id`=CASE `guid`
    WHEN 524011 THEN 65342 -- Shado-Pan Garrison: non-objective version
    WHEN 526142 THEN 61694 -- Feeding Pits: quest objective
END
WHERE (`guid`=524011 AND `id`=61694 AND `areaId`=6197)
   OR (`guid`=526142 AND `id`=65342 AND `areaId`=6420);

UPDATE `creature_template`
SET `gossip_menu_id`=15984, `AIName`='SmartAI'
WHERE `entry`=61694 AND `ScriptName`='';

DELETE FROM `npc_text` WHERE `ID` IN (23015,23017);
INSERT INTO `npc_text`
(`ID`,`text0_0`,`text0_1`,`BroadcastTextID0`,`lang0`,`Probability0`,`VerifiedBuild`) VALUES
(23015,'You... Shado-Pan. You\'re here to help me?','',66376,0,1,18414),
(23017,'My son... he\'s here? Alive!?','',66377,0,1,18414);

DELETE FROM `gossip_menu` WHERE `MenuID` IN (15984,15985);
INSERT INTO `gossip_menu` (`MenuID`,`TextID`,`VerifiedBuild`) VALUES
(15984,23015,18414),
(15985,23017,18414);

DELETE FROM `gossip_menu_option` WHERE `MenuID` IN (15984,15985);
INSERT INTO `gossip_menu_option`
(`MenuID`,`OptionID`,`OptionIcon`,`OptionText`,`OptionBroadcastTextID`,
 `OptionType`,`OptionNpcflag`,`ActionMenuID`,`ActionPoiID`,`BoxCoded`,
 `BoxMoney`,`BoxText`,`BoxBroadcastTextID`,`VerifiedBuild`) VALUES
(15984,0,0,'Yes. Your son, Ku-Mo, has been looking for you.',66378,1,1,15985,0,0,0,NULL,0,18414),
(15985,0,0,'He\'s at the Shado-Pan Garrison right now. Here\'s a kite. Go see him!',66379,1,1,0,0,0,0,NULL,0,18414);

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId`=15
  AND `SourceGroup` IN (15984,15985) AND `SourceEntry`=0;
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
 `ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,
 `ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`) VALUES
(15,15984,0,0,0,9,0,30933,0,0,0,0,0,'','Sentinel Ku-Yao - First response requires Seeking Father active'),
(15,15985,0,0,0,9,0,30933,0,0,0,0,0,'','Sentinel Ku-Yao - Final response requires Seeking Father active');

DELETE FROM `smart_scripts`
WHERE `entryorguid`=61694 AND `source_type`=0 AND `id` IN (0,1);
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,
 `event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,
 `event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,
 `action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,
 `target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,
 `target_y`,`target_z`,`target_o`,`comment`) VALUES
(61694,0,0,1,62,0,100,0,15985,0,0,0,0,85,127918,2,0,0,0,0,7,0,0,0,0,0,0,0,0,'Sentinel Ku-Yao - Final Seeking Father response - Player casts official rescue and credit spell'),
(61694,0,1,0,61,0,100,0,0,0,0,0,0,72,0,0,0,0,0,0,7,0,0,0,0,0,0,0,0,'Sentinel Ku-Yao - Seeking Father rescued - Close gossip');

COMMIT;
