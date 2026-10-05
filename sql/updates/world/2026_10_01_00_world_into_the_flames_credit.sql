-- Into the Flames (27482): award the body-burn objective to the player who
-- casts item spell 85327 on the hidden bonfire credit creature.  The original
-- credit is delayed through Vex'tul's timed farewell and targets a stored
-- summon list, so the visual sequence can run while the objective remains 0/1
-- when that stored target is unavailable.
--
-- Keep the existing SetData action, which starts Vex'tul's farewell, and link
-- direct objective credit from the same successful spell-hit event.
UPDATE `smart_scripts`
SET `link` = 1,
    `comment` = 'Into the Flames Credit - On Spellhit - Start Vex''tul farewell and award credit'
WHERE `entryorguid` = 45738
  AND `source_type` = 0
  AND `id` = 0
  AND `event_type` = 8
  AND `event_param1` = 85327;

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 45738
  AND `source_type` = 0
  AND `id` = 1;

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(45738,0,1,0,61,0,100,0,
 0,0,0,0,0,
 33,45738,0,0,0,0,0,
 7,0,0,0,0,0,0,0,
 'Into the Flames Credit - After starting Vex''tul farewell - Award credit to spell caster');
