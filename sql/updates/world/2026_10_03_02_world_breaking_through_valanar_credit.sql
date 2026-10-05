-- Breaking Through (11898)
-- Prince Valanar occasionally fails to deliver his normal creature kill
-- credit.  Award entry 25601 explicitly to the loot recipient and nearby
-- group members on death; the objective cap makes this safe if normal credit
-- was already delivered.

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 25601 AND `source_type` = 0 AND `id` = 3;

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,
 `event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,
 `event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,
 `action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,
 `target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,
 `target_z`,`target_o`,`comment`)
VALUES
(25601,0,3,0,6,0,100,0,0,0,0,0,0,33,25601,0,0,0,0,0,1,0,0,0,
 0,0,0,0,
 'Prince Valanar - On Just Died - Award Breaking Through credit to loot recipient and group');
