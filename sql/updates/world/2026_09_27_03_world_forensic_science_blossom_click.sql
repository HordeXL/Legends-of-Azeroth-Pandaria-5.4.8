-- Forensic Science gathers chlorophyll by interacting with living blossoms.
-- The NPC casts the item creation spell on the clicker, so mounted players
-- do not cast an attack or need to dismount. One item per blossom collection.
START TRANSACTION;
UPDATE `creature_template`
SET `npcflag`=`npcflag` | 16777216, `faction`=35, `AIName`='SmartAI'
WHERE `entry`=55610 AND `ScriptName`='';

DELETE FROM `npc_spellclick_spells` WHERE `npc_entry`=55610 AND `spell_id`=132251;
INSERT INTO `npc_spellclick_spells` (`npc_entry`,`spell_id`,`cast_flags`,`user_type`)
VALUES (55610,132251,2,0);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=18 AND `SourceGroup`=55610 AND `SourceEntry`=132251;
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,
`ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`)
VALUES (18,55610,132251,0,0,9,0,29815,0,0,0,0,0,'','Lurching Blossom collection - Forensic Science active');

DELETE FROM `smart_scripts` WHERE `entryorguid`=55610 AND `source_type`=0 AND `id` IN (0,1,2);
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
`event_param1`,`event_param2`,`event_param3`,`event_param4`,`action_type`,`action_param1`,
`target_type`,`comment`) VALUES
(55610,0,0,1,31,0,100,1,132251,0,0,0,83,16777216,1,'Lurching Blossom - Chlorophyll spell hit - Disable further collection'),
(55610,0,1,0,61,0,100,0,0,0,0,0,41,500,1,'Lurching Blossom - After collection - Despawn'),
(55610,0,2,0,25,0,100,0,0,0,0,0,8,0,1,'Lurching Blossom - Reset - Passive gathering target');
COMMIT;
