-- Reunited chain (31087/31679 through 31092/31359)
-- Restore missing prerequisites, alternate-branch phasing, and the persistent
-- Kovok required by Feed or Be Eaten.

START TRANSACTION;

-- Feed or Be Eaten must only become available after Reunited.
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`)
VALUES (31092, 31091)
ON DUPLICATE KEY UPDATE `PrevQuestID` = VALUES(`PrevQuestID`);

-- Restore the alternate post-Corruption branch and require both of its
-- parallel quests before By the Sea, Nevermore.
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`)
VALUES (31679, 31441), (31682, 31680)
ON DUPLICATE KEY UPDATE `PrevQuestID` = VALUES(`PrevQuestID`);

DELETE FROM `creature_queststarter`
WHERE `id`=65365 AND `quest`=31679;
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (65365,31679);

DELETE FROM `creature_questender`
WHERE `id`=65365 AND `quest`=31679;
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (65365,31679);

-- Reunited is shared by the normal Kor'ik branch and the alternate branch.
-- Keep the quest addon predecessor empty and express the alternatives as OR
-- quest-availability conditions.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId`=19 AND `SourceGroup`=0
  AND `SourceEntry`=31091 AND `ConditionTypeOrReference`=8
  AND `ConditionValue1` IN (31089,31682);

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
 `ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,
 `ConditionValue2`,`ConditionValue3`,`NegativeCondition`,`ErrorType`,
 `ErrorTextId`,`ScriptName`,`Comment`)
VALUES
(19,0,31091,0,1,8,0,31089,0,0,0,0,0,'',
 'Reunited available after normal By the Sea, Nevermore'),
(19,0,31091,0,2,8,0,31682,0,0,0,0,0,'',
 'Reunited available after alternate By the Sea, Nevermore');

-- The alternate branch must apply the same Briny Muck phase aura that exposes
-- Kaz'tik and the Reunited starting point.
DELETE FROM `spell_area`
WHERE `spell`=59074 AND `area`=6391 AND `quest_start`=31682;
INSERT INTO `spell_area`
(`spell`,`area`,`quest_start`,`quest_end`,`aura_spell`,`racemask`,`gender`,
 `autocast`,`quest_start_status`,`quest_end_status`)
VALUES (59074,6391,31682,0,0,0,2,1,64,0);

-- Kovok must remain at the dig site while players collect six turtle filets.
DELETE FROM `creature` WHERE `guid`=4000149;
INSERT INTO `creature`
(`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,
 `phaseGroup`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,
 `orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,
 `currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,
 `unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
VALUES
(4000149,62542,870,6138,6391,1,7,0,0,0,0,-1149.80,3907.40,2.20,
 0.65,300,0,0,0,1,0,0,0,0,0,0,0,'',0,0);

COMMIT;
