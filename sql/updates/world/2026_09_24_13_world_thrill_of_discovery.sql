-- The Thrill of Discovery (27511): registered SmartTriggers had no events.
-- Installed AreaTrigger.dbc: 6284 is the central chamber, 6286 the southern
-- alcove, 6288 the northern alcove. Keep native 3D entry validation.
-- Quest objectives require 45757 (mechanism), 45759 (south), 45760 (north).
DELETE FROM `smart_scripts` WHERE `source_type`=2 AND `entryorguid` IN (6284,6286,6288) AND `id`=0;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=22 AND `SourceGroup`=1 AND `SourceId`=2 AND `SourceEntry` IN (6284,6286,6288);
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`event_type`,`event_chance`,`event_param1`,`action_type`,`action_param1`,`target_type`,`comment`) VALUES (6284,2,0,46,100,6284,33,45757,7,'Thrill of Discovery - Ancient Mechanism - Exploration Credit');
INSERT INTO `conditions` (`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`Comment`) VALUES (22,1,6284,2,9,0,27511,'Exploration requires active Thrill of Discovery');
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`event_type`,`event_chance`,`event_param1`,`action_type`,`action_param1`,`target_type`,`comment`) VALUES (6286,2,0,46,100,6286,33,45759,7,'Thrill of Discovery - Southern Hieroglyphs - Exploration Credit');
INSERT INTO `conditions` (`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`Comment`) VALUES (22,1,6286,2,9,0,27511,'Exploration requires active Thrill of Discovery');
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`event_type`,`event_chance`,`event_param1`,`action_type`,`action_param1`,`target_type`,`comment`) VALUES (6288,2,0,46,100,6288,33,45760,7,'Thrill of Discovery - Northern Hieroglyphs - Exploration Credit');
INSERT INTO `conditions` (`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`Comment`) VALUES (22,1,6288,2,9,0,27511,'Exploration requires active Thrill of Discovery');
-- Correct objective markers to their actual underground trigger locations.
-- Idx1 1 = north, 2 = south, 3 = mechanism (quest_poi objective mapping).
UPDATE `quest_poi_points` SET `X`=-9090,`Y`=-1624 WHERE `QuestID`=27511 AND `Idx1`=1 AND `Idx2`=0;
UPDATE `quest_poi_points` SET `X`=-9433,`Y`=-1621 WHERE `QuestID`=27511 AND `Idx1`=2 AND `Idx2`=0;
UPDATE `quest_poi_points` SET `X`=-9260,`Y`=-1552 WHERE `QuestID`=27511 AND `Idx1`=3 AND `Idx2`=0;
