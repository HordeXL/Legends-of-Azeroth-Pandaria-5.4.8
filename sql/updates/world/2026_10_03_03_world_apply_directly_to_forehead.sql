-- Apply Directly to the Forehead (30089): summon the quest-specific
-- Manifestation of Despair instead of the ambient Essence of Despair.

UPDATE `smart_scripts`
SET `action_param1` = 58312,
    `comment` = 'Despondent Warden of Zhu - On Mask SpellHit - Summon Manifestation of Despair'
WHERE `source_type` = 0
  AND `entryorguid` IN (57457, 58242)
  AND `id` = 4
  AND `event_type` = 61
  AND `action_type` = 12;

UPDATE `creature_template`
SET `AIName` = 'SmartAI',
    `ScriptName` = ''
WHERE `entry` = 58312;

DELETE FROM `smart_scripts`
WHERE `source_type` = 0
  AND `entryorguid` = 58312;

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(58312,0,0,1,54,0,100,0,0,0,0,0,0,2,14,0,0,0,0,0,1,0,0,0,0,0,0,0,0,
 'Manifestation of Despair - Just Summoned - Set Hostile Faction'),
(58312,0,1,0,61,0,100,0,0,0,0,0,0,49,0,0,0,0,0,0,21,20,0,0,0,0,0,0,0,
 'Manifestation of Despair - Just Summoned - Attack Closest Player'),
(58312,0,2,0,6,0,100,0,0,0,0,0,0,45,1,0,0,0,0,0,23,0,0,0,0,0,0,0,0,
 'Manifestation of Despair - On Death - Notify Summoning Warden');
