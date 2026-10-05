-- Across Transborea (11930): restore the missing personal evacuee escort.
-- The quest accept spell summons an evacuee owned by the player. The invisible
-- destination generator then signals that evacuee, which completes the quest
-- for its owner after the retail dialogue sequence.

UPDATE `creature_template`
SET `AIName` = 'SmartAI', `ScriptName` = ''
WHERE `entry` IN (26158, 26162, 26167);

DELETE FROM `smart_scripts`
WHERE (`source_type` = 0 AND `entryorguid` IN (26158, 26162, 26167))
   OR (`source_type` = 9 AND `entryorguid` BETWEEN 2616700 AND 2616703);

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,
 `target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(26158,0,0,0,19,0,100,0,11930,0,0,0,0,85,46657,2,0,0,0,0,7,0,0,0,0,0,0,0,0,
 'Mother Tauranook - On Quest 11930 Accepted - Invoker Cast Taunkale Evacuee'),

(26162,0,0,0,1,0,100,0,0,0,1000,1000,0,11,46677,0,0,0,0,0,19,26167,0,0,0,0,0,0,0,
 'Transborea Generator - OOC - Cast Evacuee Reaches Dragonblight'),

(26167,0,0,0,25,0,100,0,0,0,0,0,0,11,46669,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - On Reset - Cast Evacuee Random Action'),
(26167,0,1,0,8,0,100,512,46663,0,0,0,0,87,2616700,2616701,2616702,0,0,0,1,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - On Evacuee Random Action - Run Random Action List'),
(26167,0,2,0,8,0,100,513,46677,0,0,0,0,80,2616703,2,0,0,0,0,1,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - On Reaching Dragonblight - Run Completion Action List'),

(2616700,9,0,0,0,0,100,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - Random Action 1 - Say Line 0'),

(2616701,9,0,0,0,0,100,0,0,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - Random Action 2 - Say Line 1'),
(2616701,9,1,0,0,0,100,0,0,0,0,0,0,11,46694,0,0,0,0,0,19,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - Random Action 2 - Cast Feed'),

(2616702,9,0,0,0,0,100,0,0,0,0,0,0,11,46670,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - Random Action 3 - Summon Transborea Monster'),
(2616702,9,1,0,0,0,100,0,0,0,0,0,0,1,2,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - Random Action 3 - Say Line 2'),

(2616703,9,0,0,0,0,100,0,0,0,0,0,0,28,46669,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - Completion - Remove Random Action Aura'),
(2616703,9,1,0,0,0,100,0,0,0,0,0,0,1,3,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - Completion - Say Line 3'),
(2616703,9,2,0,0,0,100,0,6000,6000,0,0,0,1,4,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - Completion - Say Line 4'),
(2616703,9,3,0,0,0,100,0,6000,6000,0,0,0,1,5,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - Completion - Say Line 5'),
(2616703,9,4,0,0,0,100,0,6000,6000,0,0,0,1,6,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - Completion - Say Line 6'),
(2616703,9,5,0,0,0,100,0,6000,6000,0,0,0,1,7,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - Completion - Say Line 7'),
(2616703,9,6,0,0,0,100,0,0,0,0,0,0,11,46676,0,0,0,0,0,23,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - Completion - Complete Across Transborea For Owner'),
(2616703,9,7,0,0,0,100,0,0,0,0,0,0,41,3000,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
 'Taunkale Evacuee - Completion - Despawn');

-- Recover the arrival when the guardian falls behind the invisible generator.
-- Wartook is at the real destination, so proximity to him is authoritative.
UPDATE `creature_template`
SET `AIName` = 'SmartAI', `ScriptName` = ''
WHERE `entry` = 26156;

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 26156 AND `source_type` = 0;

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,
 `target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(26156,0,0,0,10,0,100,0,1,20,2000,2000,1,15,11930,0,0,0,0,0,7,0,0,0,0,0,0,0,0,
 'Wartook Iceborn - Player Arrives - Complete Across Transborea');

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 22
  AND `SourceGroup` = 1
  AND `SourceEntry` = 26156
  AND `SourceId` = 0;

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
 `ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,`ConditionValue3`,
 `NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`)
VALUES
(22,1,26156,0,0,9,0,11930,0,0,0,0,0,'',
 'Wartook arrival credit requires active Across Transborea');

-- Both the objective and turn-in arrows pointed away from Wartook.
UPDATE `quest_poi_points`
SET `X` = 3572, `Y` = 3057
WHERE `QuestID` = 11930
  AND `BlobIndex` IN (0, 1);
