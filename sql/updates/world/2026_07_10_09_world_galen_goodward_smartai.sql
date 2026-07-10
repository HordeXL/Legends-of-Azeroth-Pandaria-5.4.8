-- Migrate Galen Goodward's complete escort from obsolete script_waypoint/C++
-- handling to the source-backed TrinityCore SmartAI implementation.

SET @GALEN := 5391;

UPDATE `creature_template`
SET `AIName`='SmartAI', `ScriptName`=''
WHERE `entry`=@GALEN AND `ScriptName`='';

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(@GALEN,0,0,0,11,0,100,0,0,0,0,0,0,22,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Galen Goodward - On Respawn - Set Event Phase 1'),
(@GALEN,0,1,0,4,0,100,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Galen Goodward - On Aggro - Say Line 0'),
(@GALEN,0,2,0,19,0,100,0,1393,0,0,0,0,80,539100,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Galen Goodward - On Quest 1393 Taken - Run Script'),
(@GALEN,0,3,0,40,0,100,0,1,0,0,0,0,54,3000,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Galen Goodward - On Waypoint 1 - Pause'),
(@GALEN,0,4,5,40,0,100,0,21,0,0,0,0,59,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Galen Goodward - On Waypoint 21 - Run'),
(@GALEN,0,5,6,61,0,100,0,0,0,0,0,0,66,0,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Galen Goodward - On Link - Face Stored Target'),
(@GALEN,0,6,7,61,0,100,0,0,0,0,0,0,1,3,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Galen Goodward - On Link - Say Line 3'),
(@GALEN,0,7,8,61,0,100,0,0,0,0,0,0,1,4,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Galen Goodward - On Link - Say Line 4'),
(@GALEN,0,8,9,61,0,100,0,0,0,0,0,0,1,5,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Galen Goodward - On Link - Say Line 5'),
(@GALEN,0,9,0,61,0,100,0,0,0,0,0,0,15,1393,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Galen Goodward - On Link - Quest Credit 1393'),
(@GALEN,0,10,0,40,0,100,0,22,0,0,0,0,41,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Galen Goodward - On Waypoint 22 - Despawn'),
(@GALEN,0,11,0,38,1,100,0,0,1,60000,60000,0,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Galen Goodward - On Data 0 1 - Say Line 1'),
(@GALEN,0,12,0,6,0,100,0,0,0,0,0,0,6,1393,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Galen Goodward - On Death - Fail Quest 1393'),
(539100,9,0,0,0,0,100,0,0,0,0,0,0,64,1,0,0,0,0,0,16,0,0,0,0,0,0,0,0,'Galen Goodward - Script - Store Target'),
(539100,9,1,0,0,0,100,0,0,0,0,0,0,22,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Galen Goodward - Script - Set Phase 0'),
(539100,9,2,0,0,0,100,0,0,0,0,0,0,83,2,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Galen Goodward - Script - Remove Questgiver'),
(539100,9,3,0,0,0,100,0,0,0,0,0,0,2,250,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Galen Goodward - Script - Set Faction 250'),
(539100,9,4,0,0,0,100,0,0,0,0,0,0,19,256,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Galen Goodward - Script - Remove Player Immunity'),
(539100,9,5,0,0,0,100,0,0,0,0,0,0,1,2,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Galen Goodward - Script - Say Line 2'),
(539100,9,6,0,0,0,100,0,3000,3000,0,0,0,9,0,0,0,0,0,0,20,37118,0,0,0,0,0,0,0,'Galen Goodward - Script - Open Cage'),
(539100,9,7,0,0,0,100,0,0,0,0,0,0,53,0,5391,0,0,0,2,1,0,0,0,0,0,0,0,0,'Galen Goodward - Script - Start Waypoints'),
(2387,2,0,0,46,0,100,0,2387,0,0,0,0,45,0,1,0,0,0,0,19,5391,20,0,0,0,0,0,0,'Galen Escape AreaTrigger - Set Data 0 1')
ON DUPLICATE KEY UPDATE `link`=VALUES(`link`),`event_type`=VALUES(`event_type`),`event_phase_mask`=VALUES(`event_phase_mask`),`event_chance`=VALUES(`event_chance`),`event_flags`=VALUES(`event_flags`),`event_param1`=VALUES(`event_param1`),`event_param2`=VALUES(`event_param2`),`event_param3`=VALUES(`event_param3`),`event_param4`=VALUES(`event_param4`),`event_param5`=VALUES(`event_param5`),`action_type`=VALUES(`action_type`),`action_param1`=VALUES(`action_param1`),`action_param2`=VALUES(`action_param2`),`action_param3`=VALUES(`action_param3`),`action_param4`=VALUES(`action_param4`),`action_param5`=VALUES(`action_param5`),`action_param6`=VALUES(`action_param6`),`target_type`=VALUES(`target_type`),`target_param1`=VALUES(`target_param1`),`target_param2`=VALUES(`target_param2`),`target_param3`=VALUES(`target_param3`),`target_param4`=VALUES(`target_param4`),`target_x`=VALUES(`target_x`),`target_y`=VALUES(`target_y`),`target_z`=VALUES(`target_z`),`target_o`=VALUES(`target_o`),`comment`=VALUES(`comment`);

INSERT INTO `areatrigger_scripts` (`entry`,`ScriptName`) VALUES (2387,'SmartTrigger')
ON DUPLICATE KEY UPDATE `ScriptName`=VALUES(`ScriptName`);

-- Preserve all existing authentic text rows while remapping old C++ groups.
UPDATE `creature_text` SET `GroupID`=`GroupID`+10 WHERE `CreatureID`=@GALEN AND `GroupID`<10;
UPDATE `creature_text`
SET `GroupID`=CASE `BroadcastTextId`
  WHEN 1628 THEN 0 WHEN 1629 THEN 0 WHEN 1630 THEN 0
  WHEN 1631 THEN 1 WHEN 7124 THEN 1 WHEN 1854 THEN 2
  WHEN 1855 THEN 3 WHEN 2076 THEN 4 WHEN 1856 THEN 5 END,
`ID`=CASE `BroadcastTextId`
  WHEN 1628 THEN 0 WHEN 1629 THEN 1 WHEN 1630 THEN 2
  WHEN 1631 THEN 0 WHEN 7124 THEN 1 ELSE 0 END
WHERE `CreatureID`=@GALEN AND `GroupID`>=10
  AND `BroadcastTextId` IN (1628,1629,1630,1631,7124,1854,1855,2076,1856);

INSERT INTO `waypoints` (`entry`,`pointid`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`point_comment`)
SELECT `entry`,`pointid`+1,`location_x`,`location_y`,`location_z`,0,0,'Galen Goodward'
FROM `script_waypoint` WHERE `entry`=@GALEN
ON DUPLICATE KEY UPDATE `position_x`=VALUES(`position_x`),`position_y`=VALUES(`position_y`),`position_z`=VALUES(`position_z`),`delay`=0,`point_comment`=VALUES(`point_comment`);

-- Remove the obsolete copy only after the complete SmartAI path exists.
DELETE `sw` FROM `script_waypoint` `sw`
WHERE `sw`.`entry`=@GALEN
  AND (SELECT COUNT(*) FROM `waypoints` WHERE `entry`=@GALEN)=22
  AND (SELECT COUNT(*) FROM `smart_scripts` WHERE `entryorguid`=@GALEN AND `source_type`=0)=13
  AND (SELECT COUNT(*) FROM `smart_scripts` WHERE `entryorguid`=539100 AND `source_type`=9)=8;
