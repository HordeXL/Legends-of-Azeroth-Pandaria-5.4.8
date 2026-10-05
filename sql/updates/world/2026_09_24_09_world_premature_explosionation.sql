-- Premature Explosionation (27141): functional Powder Keg interaction.
-- Both overlapping keg objects cast 84265, a dummy aura with no handler here.
-- Use the existing Dusty Explosion spell (84509) through native GO spellcasting
-- and grant objective 45143 only to the clicking player with the active quest.
-- This is an explosion/quest-credit fallback, not the original cinematic.
-- Keep the kegs reusable for other players and preserve their positions.
UPDATE `gameobject_template` SET `AIName`='SmartGameObjectAI', `data0`=84509
WHERE `entry` IN (205241,205394) AND `ScriptName`='' AND `data0` IN (84265,84509);
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (205241,205394) AND `source_type`=1 AND `id`=0;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`event_type`,`event_chance`,`event_param1`,`action_type`,`action_param1`,`target_type`,`comment`) VALUES
(205241,1,0,64,100,1,33,45143,7,'Powder Keg - On Use - Premature Explosionation Credit'),
(205394,1,0,64,100,1,33,45143,7,'Powder Keg - On Use - Premature Explosionation Credit');
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=22 AND `SourceGroup`=1
 AND `SourceEntry` IN (205241,205394) AND `SourceId`=1;
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`Comment`) VALUES
(22,1,205241,1,9,0,27141,'Powder Keg credit requires active Premature Explosionation'),
(22,1,205394,1,9,0,27141,'Powder Keg credit requires active Premature Explosionation');
