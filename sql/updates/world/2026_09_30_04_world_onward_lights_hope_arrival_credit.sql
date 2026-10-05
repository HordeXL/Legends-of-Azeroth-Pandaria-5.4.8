-- Onward, to Light's Hope Chapel (27373): the player rides caravan 45423,
-- which is itself attached to harness 45436 in seat 2. At the final waypoint,
-- credit the player through that vehicle passenger before running the existing
-- SetData arrival chain. The transferred SmartAI target list is not reliable
-- once the nested vehicle begins unloading and despawning.
UPDATE `smart_scripts`
SET `link` = 5,
    `action_type` = 33,
    `action_param1` = 45400,
    `action_param2` = 0,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `target_type` = 29,
    `target_param1` = 2,
    `target_param2` = 0,
    `target_param3` = 0,
    `target_param4` = 0,
    `comment` = 'Fiona''s Caravan Harness - On WP 82 - Credit caravan passenger'
WHERE `entryorguid` = 45436
  AND `source_type` = 0
  AND `id` = 3
  AND `event_type` = 40
  AND `event_param1` = 82;

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 45436 AND `source_type` = 0 AND `id` = 5;

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`event_type`,`event_chance`,
 `action_type`,`action_param1`,`action_param2`,
 `target_type`,`target_param1`,`comment`) VALUES
(45436,0,5,61,100,45,2,0,29,2,
 'Fiona''s Caravan Harness - After arrival credit - Run existing SetData 2 chain');
