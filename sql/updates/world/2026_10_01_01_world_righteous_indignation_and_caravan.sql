-- Onward, to Light's Hope Chapel (27373): Ride Vehicle (46598) boards the
-- player in wagon seat 0.  Fiona was also installed in seat 0, so boarding the
-- player removed Fiona; the wagon's passenger-removed event then stripped its
-- ride aura and detached wagon 45423 from harness 45436.  Seats 1-3 are the
-- wagon passenger attachments and leave seat 0 available for the player.
DELETE FROM `vehicle_template_accessory`
WHERE `entry` = 45423
  AND `accessory_entry` IN (46192, 46193, 46191);

INSERT INTO `vehicle_template_accessory`
(`entry`,`accessory_entry`,`seat_id`,`minion`,`description`,`summontype`,`summontimer`) VALUES
(45423,46192,1,1,'Fiona''s Caravan - Fiona',8,0),
(45423,46193,2,1,'Fiona''s Caravan - Tarenar Sunstrike',8,0),
(45423,46191,3,1,'Fiona''s Caravan - Gidwin Goldbraids',8,0);

-- Target type 29 (vehicle accessory) is rejected by this core's SmartAI
-- validator, so the previous arrival rows never loaded.  The harness already
-- stores its summoning player as target list 1.  Award that player at waypoint
-- 82, then notify the now-attached nearby wagon to run its existing exit chain.
UPDATE `smart_scripts`
SET `link` = 5,
    `action_type` = 33,
    `action_param1` = 45400,
    `action_param2` = 0,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `target_type` = 12,
    `target_param1` = 1,
    `target_param2` = 0,
    `target_param3` = 0,
    `target_param4` = 0,
    `comment` = 'Fiona''s Caravan Harness - On WP 82 - Credit stored summoning player'
WHERE `entryorguid` = 45436
  AND `source_type` = 0
  AND `id` = 3
  AND `event_type` = 40
  AND `event_param1` = 82;

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 45436
  AND `source_type` = 0
  AND `id` = 5;

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(45436,0,5,0,61,0,100,0,
 0,0,0,0,0,
 45,2,0,0,0,0,0,
 19,45423,20,0,0,0,0,0,
 'Fiona''s Caravan Harness - After arrival credit - Run wagon SetData 2 exit chain');
