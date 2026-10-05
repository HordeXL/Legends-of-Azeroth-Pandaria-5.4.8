-- Restore Grookin Hill services and Beyond the Horizon (29941) reports.
START TRANSACTION;
-- These quest services must remain usable regardless of Hozen reputation.
UPDATE `creature_template` SET `faction`=35,`npcflag`=`npcflag` | 8193 WHERE `entry`=60952;
UPDATE `creature_template` SET `faction`=35,`npcflag`=`npcflag` | 3 WHERE `entry`=56358;
UPDATE `creature_template` SET `npcflag`=`npcflag` | 1 WHERE `entry` IN (56340,56477,56478);

-- Their assigned menus are empty; reporting is handled on gossip hello.
-- Direct credit avoids the unimplemented report spell effects.
UPDATE `smart_scripts`
SET `action_type`=33,`action_param1`=`entryorguid`,
    `action_param2`=0,`action_param3`=0,`action_param4`=0,`action_param5`=0,`action_param6`=0,
    `target_type`=7,`comment`='Beyond the Horizon - On gossip hello - Report credit to quest holder'
WHERE `entryorguid` IN (56336,56340,56477,56478) AND `source_type`=0 AND `id`=0 AND `event_type`=64;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=22 AND `SourceGroup`=1
    AND `SourceEntry` IN (56336,56340,56477,56478) AND `SourceId`=0 AND `ConditionTypeOrReference`=9 AND `ConditionValue1`=29941;
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
 `ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`Comment`) VALUES
(22,1,56336,0,0,9,0,29941,'Kah Kah report requires active Beyond the Horizon'),
(22,1,56340,0,0,9,0,29941,'Shokia report requires active Beyond the Horizon'),
(22,1,56477,0,0,9,0,29941,'Gorrok report requires active Beyond the Horizon'),
(22,1,56478,0,0,9,0,29941,'Kiryn report requires active Beyond the Horizon');

DELETE FROM `gossip_menu_option` WHERE `MenuID`=14321 AND `OptionID`=0;
INSERT INTO `gossip_menu_option`
(`MenuID`,`OptionID`,`OptionIcon`,`OptionText`,`OptionType`,`OptionNpcflag`)
VALUES (14321,0,2,'I need a ride.',4,8192);
COMMIT;
