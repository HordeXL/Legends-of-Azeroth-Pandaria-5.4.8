-- Restore Hira Snowdawn's historical ten-minute flight around Krasus' Landing.
-- The 11-point path already exists in `waypoints` under entry 31238. The base
-- dump lost the two timed action lists and shifted CALL_TIMED_ACTIONLIST into
-- action_param1 on both caller rows.

UPDATE `smart_scripts`
SET `action_type` = 80,
    `action_param1` = 3123800,
    `action_param2` = 0
WHERE `entryorguid` = 31238
  AND `source_type` = 0
  AND `id` = 0
  AND `event_type` = 1
  AND `action_type` = 0
  AND `action_param1` = 80
  AND `action_param2` = 3123800;

UPDATE `smart_scripts`
SET `action_type` = 80,
    `action_param1` = 3123801,
    `action_param2` = 0,
    `comment` = 'Hira - Waypoint 11 Reached - Run Action List'
WHERE `entryorguid` = 31238
  AND `source_type` = 0
  AND `id` = 1
  AND `event_type` = 40
  AND `event_param1` = 11
  AND `action_type` = 0
  AND `action_param1` = 80
  AND `action_param2` = 3123801;

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,
 `target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(3123800,9,0,0,0,0,100,0,0,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Hira - Action List - Talk (Emote)'),
(3123800,9,1,0,0,0,100,0,5000,5000,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Hira - Action List - Talk'),
(3123800,9,2,0,0,0,100,0,0,0,0,0,0,18,33554432,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Hira - Action List - Set UNIT_FLAG_NOT_SELECTABLE'),
(3123800,9,3,0,0,0,100,0,0,0,0,0,0,53,1,31238,0,0,0,0,1,0,0,0,0,0,0,0,0,'Hira - Action List - Start Waypoints'),
(3123801,9,0,0,0,0,100,0,0,0,0,0,0,66,0,0,0,0,0,0,8,0,0,0,0,5815.272,473.4902,658.7961,4.660029,'Hira - Action List - Set Orientation'),
(3123801,9,1,0,0,0,100,0,0,0,0,0,0,19,33554432,0,0,0,0,0,1,0,0,0,0,0,0,0,0,'Hira - Action List - Remove UNIT_FLAG_NOT_SELECTABLE')
ON DUPLICATE KEY UPDATE
`event_type`=VALUES(`event_type`),
`event_phase_mask`=VALUES(`event_phase_mask`),
`event_chance`=VALUES(`event_chance`),
`event_flags`=VALUES(`event_flags`),
`event_param1`=VALUES(`event_param1`),
`event_param2`=VALUES(`event_param2`),
`event_param3`=VALUES(`event_param3`),
`event_param4`=VALUES(`event_param4`),
`event_param5`=VALUES(`event_param5`),
`action_type`=VALUES(`action_type`),
`action_param1`=VALUES(`action_param1`),
`action_param2`=VALUES(`action_param2`),
`action_param3`=VALUES(`action_param3`),
`action_param4`=VALUES(`action_param4`),
`action_param5`=VALUES(`action_param5`),
`action_param6`=VALUES(`action_param6`),
`target_type`=VALUES(`target_type`),
`target_param1`=VALUES(`target_param1`),
`target_param2`=VALUES(`target_param2`),
`target_param3`=VALUES(`target_param3`),
`target_param4`=VALUES(`target_param4`),
`target_x`=VALUES(`target_x`),
`target_y`=VALUES(`target_y`),
`target_z`=VALUES(`target_z`),
`target_o`=VALUES(`target_o`),
`comment`=VALUES(`comment`);
