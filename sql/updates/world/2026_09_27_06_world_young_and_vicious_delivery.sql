-- Young and Vicious: register delivery when the ridden Swiftclaw reaches the pens.
-- Notera (guid 251761) is the existing trainer beside the raptor pen trigger 5675.
START TRANSACTION;
UPDATE `smart_scripts` SET `link`=11
WHERE `entryorguid`=38002 AND `source_type`=0 AND `id`=6;
DELETE FROM `smart_scripts` WHERE `entryorguid`=38002 AND `source_type`=0 AND `id` BETWEEN 11 AND 13;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`action_type`,`action_param1`,`target_type`,`comment`) VALUES
(38002,0,11,0,61,0,100,0,0,0,0,0,22,1,1,'Swiftclaw - Passenger boarded link - Enable delivery phase'),
(38002,0,12,13,75,1,100,1,251761,0,35,1000,33,38002,23,'Swiftclaw - Ridden near raptor pens - Delivery credit to rider'),
(38002,0,13,0,61,0,100,0,0,0,0,0,28,48678,1,'Swiftclaw - Delivery credit link - Dismount rider');

-- Rebuild these two objective POIs rather than swapping on every application.
DELETE FROM `quest_poi_points` WHERE `QuestID`=24626 AND `Idx1` IN (1,2);
INSERT INTO `quest_poi_points` (`QuestID`,`BlobIndex`,`Idx1`,`Idx2`,`X`,`Y`,`VerifiedBuild`) VALUES
(24626,0,1,0,-1309,-5451,0),
(24626,0,2,0,-1561,-5386,0),
(24626,0,2,1,-1531,-5373,0),
(24626,0,2,2,-1504,-5351,0),
(24626,0,2,3,-1491,-5331,0),
(24626,0,2,4,-1479,-5301,0),
(24626,0,2,5,-1491,-5259,0),
(24626,0,2,6,-1524,-5221,0),
(24626,0,2,7,-1561,-5219,0),
(24626,0,2,8,-1623,-5263,0),
(24626,0,2,9,-1633,-5308,0),
(24626,0,2,10,-1633,-5343,0),
(24626,0,2,11,-1603,-5381,0);
COMMIT;
