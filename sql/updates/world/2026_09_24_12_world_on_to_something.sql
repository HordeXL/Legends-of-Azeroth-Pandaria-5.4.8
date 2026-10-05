-- On to Something (27196): deterministic escort summon and player ownership.
-- Spell 84475 uses a nearby-entry destination without a target condition here.
-- Summon 45238 directly at the starting Harrison so the next linked action's
-- 3-yard search reliably transfers stored player list 1 to the new escort.
-- Keep the existing dialogue, waypoints, jumps and credit 45238 sequence.
UPDATE `smart_scripts`
SET `action_type`=12, `action_param1`=45238, `action_param2`=3,
    `action_param3`=300000, `action_param4`=0, `action_param5`=0, `action_param6`=0,
    `comment`='Harrison Jones - Gossip Start - Summon Escort At Own Position'
WHERE `entryorguid`=45180 AND `source_type`=0 AND `id`=2
  AND `action_type` IN (11,12);

-- WP_START copies its targets to SMART_ESCORT_TARGETS. SELF supplied Harrison
-- instead of the player; use the same stored list as the quest credit event.
UPDATE `smart_scripts`
SET `target_type`=12, `target_param1`=1,
    `comment`='Harrison Jones - Start Escort - Track Stored Player List 1'
WHERE `entryorguid`=4523800 AND `source_type`=9 AND `id`=2 AND `action_type`=53;

-- Recover players who reached the actual chamber but lost escort credit.
-- The destination NPC is deep underground: 3D distance plus LOS prevents
-- granting credit to players merely passing above the chamber.
UPDATE `creature_template` SET `AIName`='SmartAI'
WHERE `entry`=45296 AND `AIName`='' AND `ScriptName`='';
DELETE FROM `smart_scripts` WHERE `entryorguid`=45296 AND `source_type`=0 AND `id`=0;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`event_type`,`event_chance`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`target_type`,`comment`)
VALUES (45296,0,0,10,100,1,20,2000,2000,1,33,45238,7,'Harrison In Chamber - Player Arrives - On to Something Credit');
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=22 AND `SourceGroup`=1 AND `SourceEntry`=45296 AND `SourceId`=0;
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`Comment`)
VALUES (22,1,45296,0,9,0,27196,'Chamber arrival credit requires active On to Something');
