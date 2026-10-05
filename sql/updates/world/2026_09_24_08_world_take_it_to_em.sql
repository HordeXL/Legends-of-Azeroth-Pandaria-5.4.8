-- Take it to 'Em! (27993): award the missing Khartut's Tomb investigation.
-- Objective 265343 requires creature credit 47318, but no existing script
-- awards it. Harrison Jones (44860) is the quest ender at the destination;
-- the investigation POI is about 13 yards away from his spawn.
-- Give credit to the approaching player within 20 yards and line of sight,
-- only while the quest is active. Preserve questgiver flags and quest chain.
UPDATE `creature_template` SET `AIName` = 'SmartAI'
WHERE `entry` = 44860 AND `AIName` = '' AND `ScriptName` = '';

DELETE FROM `smart_scripts` WHERE `entryorguid` = 44860 AND `source_type` = 0 AND `id` = 0;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
 `action_type`,`action_param1`,`target_type`,`comment`)
VALUES (44860,0,0,0,10,0,100,0,1,20,2000,2000,1,33,47318,7,
 'Harrison Jones - Player Near Tomb With Quest 27993 - Investigation Credit');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1
 AND `SourceEntry` = 44860 AND `SourceId` = 0;
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
 `ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`Comment`)
VALUES (22,1,44860,0,0,9,0,27993,'Harrison tomb investigation requires active Take it to Em');
