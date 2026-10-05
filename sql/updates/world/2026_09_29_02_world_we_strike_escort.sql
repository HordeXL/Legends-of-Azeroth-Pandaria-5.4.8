-- Restore the complete escort event for quest 11592, We Strike!.
-- Longrunner Proudhoof starts the event immediately on quest acceptance,
-- escorts the player through two encounters, and grants event completion
-- when Force-Commander Steeljaw dies.

CREATE TABLE IF NOT EXISTS `_backup_creature_template_we_strike_20260929`
LIKE `creature_template`;
INSERT INTO `_backup_creature_template_we_strike_20260929`
SELECT `ct`.* FROM `creature_template` AS `ct`
WHERE `ct`.`entry` IN (25335,25336,25338,25359)
  AND NOT EXISTS
  (
      SELECT 1 FROM `_backup_creature_template_we_strike_20260929` AS `b`
      WHERE `b`.`entry` = `ct`.`entry`
  );

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_we_strike_20260929`
LIKE `smart_scripts`;
INSERT INTO `_backup_smart_scripts_we_strike_20260929`
SELECT `s`.* FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` IN (25335,25336,25338,25359,2533500,2533501,2533600)
  AND NOT EXISTS
  (
      SELECT 1 FROM `_backup_smart_scripts_we_strike_20260929` AS `b`
      WHERE `b`.`entryorguid` = `s`.`entryorguid`
        AND `b`.`source_type` = `s`.`source_type`
        AND `b`.`id` = `s`.`id`
  );

CREATE TABLE IF NOT EXISTS `_backup_waypoints_we_strike_20260929`
LIKE `waypoints`;
INSERT INTO `_backup_waypoints_we_strike_20260929`
SELECT `w`.* FROM `waypoints` AS `w`
WHERE `w`.`entry` = 25335
  AND NOT EXISTS
  (
      SELECT 1 FROM `_backup_waypoints_we_strike_20260929` AS `b`
      WHERE `b`.`entry` = `w`.`entry` AND `b`.`pointid` = `w`.`pointid`
  );

CREATE TABLE IF NOT EXISTS `_backup_creature_summon_groups_we_strike_20260929`
LIKE `creature_summon_groups`;
INSERT INTO `_backup_creature_summon_groups_we_strike_20260929`
SELECT `csg`.* FROM `creature_summon_groups` AS `csg`
WHERE `csg`.`summonerId` = 25335 AND `csg`.`summonerType` = 0
  AND `csg`.`groupId` = 1;

UPDATE `creature_template`
SET `AIName` = 'SmartAI', `ScriptName` = ''
WHERE `entry` IN (25335,25336,25338,25359);

DELETE FROM `waypoints` WHERE `entry` = 25335;
INSERT INTO `waypoints`
(`entry`,`pointid`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`point_comment`) VALUES
(25335,1,4121.4,5791.31,62.7287,NULL,0,'Longrunner Proudhoof'),
(25335,2,4101.44,5799.44,67.9436,NULL,0,'Longrunner Proudhoof'),
(25335,3,4083.93,5805.44,71.3716,NULL,0,'Longrunner Proudhoof'),
(25335,4,4068.87,5807.64,73.8172,NULL,0,'Longrunner Proudhoof'),
(25335,5,4052.77,5802.65,75.0918,NULL,0,'Longrunner Proudhoof'),
(25335,6,4038.37,5795.23,75.4015,NULL,0,'Longrunner Proudhoof'),
(25335,7,4025.04,5789.23,75.1947,NULL,0,'Longrunner Proudhoof'),
(25335,8,4006.38,5787.3,73.1468,NULL,0,'Longrunner Proudhoof'),
(25335,9,3984.42,5778.06,73.177,NULL,0,'Longrunner Proudhoof'),
(25335,10,3952.68,5758.44,70.4851,NULL,0,'Longrunner Proudhoof'),
(25335,11,3919.01,5753.34,69.2403,NULL,0,'Longrunner Proudhoof'),
(25335,12,3894.65,5745.7,70.362,NULL,0,'Longrunner Proudhoof'),
(25335,13,3883.36,5725.31,67.5505,NULL,0,'Longrunner Proudhoof');

DELETE FROM `creature_summon_groups`
WHERE `summonerId` = 25335 AND `summonerType` = 0 AND `groupId` = 1;
INSERT INTO `creature_summon_groups`
(`summonerId`,`summonerType`,`groupId`,`entry`,`position_x`,`position_y`,`position_z`,`orientation`,`summonType`,`summonTime`,`Comment`) VALUES
(25335,0,1,25351,3981.68,5766.3,71.6903,1.50855,3,100000,'We Strike! - Ghostly Sage'),
(25335,0,1,25351,3972.01,5783.71,74.185,5.85625,3,100000,'We Strike! - Ghostly Sage'),
(25335,0,1,25351,3996.72,5773.32,70.84,2.77288,3,100000,'We Strike! - Ghostly Sage'),
(25335,0,1,25350,3988.27,5792,74.1844,4.44349,3,100000,'We Strike! - Risen Longrunner'),
(25335,0,1,25351,3969.23,5768.75,72.6969,0.549799,3,100000,'We Strike! - Ghostly Sage');

DELETE FROM `smart_scripts`
WHERE `entryorguid` IN (25335,25336,25338,25359,2533500,2533501,2533600);

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(25335,0,0,1,19,0,100,0,11592,0,0,0,0,64,1,0,0,0,0,0,7,0,0,0,0,0,0,0,0,'Longrunner Proudhoof - On quest accept - Store party'),
(25335,0,1,0,61,0,100,0,0,0,0,0,0,80,2533500,2,0,0,0,0,1,0,0,0,0,0,0,0,0,'Longrunner Proudhoof - On quest accept - Start event'),
(25335,0,2,3,6,0,100,0,0,0,0,0,0,6,11592,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Longrunner Proudhoof - On death - Fail quest'),
(25335,0,3,4,61,0,100,0,0,0,0,0,0,45,3,3,0,0,0,0,19,25336,0,0,0,0,0,0,0,'Longrunner Proudhoof - On death - Despawn Ragefist'),
(25335,0,4,0,61,0,100,0,0,0,0,0,0,45,3,3,0,0,0,0,9,25338,0,200,0,0,0,0,0,'Longrunner Proudhoof - On death - Despawn guard'),
(25335,0,5,6,40,0,100,0,0,0,0,0,0,101,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Longrunner Proudhoof - On waypoint - Set home'),
(25335,0,6,7,61,0,100,0,0,0,0,0,0,45,4,4,0,0,0,0,19,25336,0,0,0,0,0,0,0,'Longrunner Proudhoof - On waypoint - Set Ragefist home'),
(25335,0,7,0,61,0,100,0,0,0,0,0,0,45,4,4,0,0,0,0,9,25338,0,200,0,0,0,0,0,'Longrunner Proudhoof - On waypoint - Set guard home'),
(25335,0,8,9,40,0,100,1,9,0,0,0,0,54,5000,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Longrunner Proudhoof - Waypoint 9 - Pause'),
(25335,0,9,10,61,0,100,0,0,0,0,0,0,1,2,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Longrunner Proudhoof - Waypoint 9 - Announce ambush'),
(25335,0,10,0,61,0,100,0,0,0,0,0,0,107,1,1,0,0,0,0,1,0,0,0,0,0,0,0,0,'Longrunner Proudhoof - Waypoint 9 - Summon ambush'),
(25335,0,11,0,40,0,100,1,10,0,0,0,0,1,3,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Longrunner Proudhoof - Waypoint 10 - Talk'),
(25335,0,12,13,40,0,100,1,13,0,0,0,0,1,4,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Longrunner Proudhoof - Waypoint 13 - Announce Steeljaw'),
(25335,0,13,14,61,0,100,0,0,0,0,0,0,101,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Longrunner Proudhoof - Waypoint 13 - Set home'),
(25335,0,14,0,61,0,100,0,0,0,0,0,0,12,25359,1,100000,0,0,0,8,0,0,0,0,3879.79,5719.11,66.5031,1.04814,'Longrunner Proudhoof - Summon Steeljaw'),
(25335,0,15,0,38,0,100,0,5,5,0,0,0,80,2533501,2,0,0,0,0,1,0,0,0,0,0,0,0,0,'Longrunner Proudhoof - Steeljaw defeated - Finish event'),
(25335,0,16,0,11,0,100,0,0,0,0,0,0,78,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Longrunner Proudhoof - On respawn - Reset'),

(2533500,9,0,0,0,0,100,0,0,0,0,0,0,81,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Longrunner Proudhoof - Event - Remove NPC flags'),
(2533500,9,1,0,0,0,100,0,0,0,0,0,0,45,1,1,0,0,0,0,19,25336,0,0,0,0,0,0,0,'Longrunner Proudhoof - Event - Activate Ragefist'),
(2533500,9,2,0,0,0,100,0,0,0,0,0,0,45,1,1,0,0,0,0,9,25338,0,200,0,0,0,0,0,'Longrunner Proudhoof - Event - Activate guard'),
(2533500,9,3,0,0,0,100,0,0,0,0,0,0,1,0,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Longrunner Proudhoof - Event - Talk'),
(2533500,9,4,0,0,0,100,0,0,0,0,0,0,2,232,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Longrunner Proudhoof - Event - Escort faction'),
(2533500,9,5,0,0,0,100,0,0,0,0,0,0,8,2,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Longrunner Proudhoof - Event - Aggressive'),
(2533500,9,6,0,0,0,100,0,0,0,0,0,0,102,0,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Longrunner Proudhoof - Event - Disable regeneration'),
(2533500,9,7,0,0,0,100,0,11000,11000,0,0,0,1,1,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Longrunner Proudhoof - Event - We strike'),
(2533500,9,8,0,0,0,100,0,1000,1000,0,0,0,45,2,2,0,0,0,0,19,25336,0,0,0,0,0,0,0,'Longrunner Proudhoof - Event - Ragefist follows'),
(2533500,9,9,0,0,0,100,0,0,0,0,0,0,45,2,2,0,0,0,0,9,25338,0,200,0,0,0,0,0,'Longrunner Proudhoof - Event - Guard follows'),
(2533500,9,10,0,0,0,100,0,0,0,0,0,0,53,2,25335,0,0,0,2,12,1,0,0,0,0,0,0,0,'Longrunner Proudhoof - Event - Start waypoints'),

(2533501,9,0,0,0,0,100,0,0,0,0,0,0,1,5,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Longrunner Proudhoof - Finish - Talk'),
(2533501,9,1,0,0,0,100,0,0,0,0,0,0,15,11592,0,0,0,0,0,12,1,0,0,0,0,0,0,0,'Longrunner Proudhoof - Finish - Complete quest'),
(2533501,9,2,0,0,0,100,0,6000,6000,0,0,0,45,3,3,0,0,0,0,19,25336,0,0,0,0,0,0,0,'Longrunner Proudhoof - Finish - Despawn Ragefist'),
(2533501,9,3,0,0,0,100,0,0,0,0,0,0,45,3,3,0,0,0,0,9,25338,0,200,0,0,0,0,0,'Longrunner Proudhoof - Finish - Despawn guard'),
(2533501,9,4,0,0,0,100,0,0,0,0,0,0,41,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Longrunner Proudhoof - Finish - Despawn'),

(25336,0,0,0,38,0,100,0,1,1,0,0,0,80,2533600,2,0,0,0,0,1,0,0,0,0,0,0,0,0,'Grunt Ragefist - Activate event'),
(25336,0,1,2,38,0,100,0,2,2,0,0,0,59,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Grunt Ragefist - Run'),
(25336,0,2,0,61,0,100,0,0,0,0,0,0,29,2,3,0,0,0,0,19,25335,0,0,0,0,0,0,0,'Grunt Ragefist - Follow Proudhoof'),
(25336,0,3,0,38,0,100,0,3,3,0,0,0,41,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Grunt Ragefist - Despawn'),
(25336,0,4,0,38,0,100,0,4,4,0,0,0,101,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Grunt Ragefist - Set home'),
(25336,0,5,0,1,0,100,0,0,0,2000,2000,0,101,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Grunt Ragefist - OOC - Set home'),
(25336,0,6,0,11,0,100,0,0,0,0,0,0,81,3,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Grunt Ragefist - On respawn - Restore NPC flags'),

(2533600,9,0,0,0,0,100,0,0,0,0,0,0,81,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Grunt Ragefist - Event - Remove NPC flags'),
(2533600,9,1,0,0,0,100,0,0,0,0,0,0,2,232,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Grunt Ragefist - Event - Escort faction'),
(2533600,9,2,0,0,0,100,0,0,0,0,0,0,8,2,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Grunt Ragefist - Event - Aggressive'),
(2533600,9,3,0,0,0,100,0,0,0,0,0,0,102,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Grunt Ragefist - Event - Disable regeneration'),

(25338,0,0,1,38,0,100,0,1,1,0,0,0,2,232,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Warsong Caravan Guard - Activate faction'),
(25338,0,1,2,61,0,100,0,0,0,0,0,0,8,2,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Warsong Caravan Guard - Aggressive'),
(25338,0,2,0,61,0,100,0,0,0,0,0,0,102,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Warsong Caravan Guard - Disable regeneration'),
(25338,0,3,4,38,0,100,0,2,2,0,0,0,59,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Warsong Caravan Guard - Run'),
(25338,0,4,0,61,0,100,0,0,0,0,0,0,29,1,2,0,0,0,0,19,25335,0,0,0,0,0,0,0,'Warsong Caravan Guard - Follow Proudhoof'),
(25338,0,5,0,38,0,100,0,3,3,0,0,0,41,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Warsong Caravan Guard - Despawn'),
(25338,0,6,0,38,0,100,0,4,4,0,0,0,101,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Warsong Caravan Guard - Set home'),
(25338,0,7,0,1,0,100,0,0,0,2000,2000,0,101,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Warsong Caravan Guard - OOC - Set home'),

(25359,0,0,0,54,0,100,0,0,0,0,0,0,49,0,0,0,0,0,0,19,25335,0,0,0,0,0,0,0,'Force-Commander Steeljaw - Attack Proudhoof'),
(25359,0,1,0,6,0,100,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Force-Commander Steeljaw - On death - Talk'),
(25359,0,2,0,6,0,100,0,0,0,0,0,0,45,5,5,0,0,0,0,19,25335,0,0,0,0,0,0,0,'Force-Commander Steeljaw - On death - Finish event'),
(25359,0,3,0,9,0,100,0,0,0,8000,13000,0,11,15284,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Force-Commander Steeljaw - Cleave'),
(25359,0,4,0,0,0,100,0,6000,9000,11000,18000,0,11,38256,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Force-Commander Steeljaw - Piercing Howl'),
(25359,0,5,0,2,0,100,1,0,50,0,0,0,11,50204,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Force-Commander Steeljaw - Steel Jaw'),
(25359,0,6,0,0,0,100,0,9000,15000,18000,24000,0,11,41056,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Force-Commander Steeljaw - Whirlwind');
