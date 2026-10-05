-- Zhu's Despair (30090): the summoned Quintessence of Despair inherited its
-- friendly template faction and could not be attacked. Make only the summoned
-- quest creature hostile and have it engage the nearby player.

UPDATE `creature_template`
SET `AIName` = 'SmartAI', `ScriptName` = ''
WHERE `entry` = 58360;

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 58360
  AND `source_type` = 0
  AND `id` IN (3, 4);

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,
 `target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(58360,0,3,4,54,0,100,0,0,0,0,0,0,2,14,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
 'Quintessence of Despair - Just Summoned - Set Hostile Faction'),
(58360,0,4,0,61,0,100,0,0,0,0,0,0,49,0,0,0,0,0,0,21,30,0,0,0,0,0,0,0,
 'Quintessence of Despair - Just Summoned - Attack Closest Player');
