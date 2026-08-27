-- Quest 29792 "Bidden to Greatness": restore one closed world gate at each
-- entrance for players who have not accepted the quest. The exact-spawn
-- visibility rules keep these base gates visible only while quest status is
-- QUEST_STATUS_NONE (0). Once the quest is accepted, SmartAI supplies and
-- opens the dedicated personal gates 211294 and 211298 instead.
--
-- The former overlap was caused by SmartScript::ProcessEvent executing the
-- SMART_EVENT_JUST_SUMMONED action twice. That core control-flow bug is now
-- fixed, so the pre-quest world gates no longer need to be removed globally.

INSERT INTO `gameobject`
(`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`)
SELECT
540026,210964,860,5736,5737,1,2,0,0,566.524,3583.47,92.1576,3.14,0,0,0,1,0,100,1,'',0
WHERE NOT EXISTS (SELECT 1 FROM `gameobject` WHERE `guid` = 540026);

INSERT INTO `gameobject`
(`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`)
SELECT
540359,210965,860,5736,5828,1,2,0,0,695.26,3600.99,142.381,3.04,0,0,0,1,0,100,1,'',0
WHERE NOT EXISTS (SELECT 1 FROM `gameobject` WHERE `guid` = 540359);

INSERT INTO `object_visibility_state`
    (`type`, `entryorguid`, `visibilityQuestID`, `visibilityQuestState`)
VALUES
    ('GameObject', -540359, 29792, 0),
    ('GameObject', -540026, 29792, 0)
ON DUPLICATE KEY UPDATE
    `visibilityQuestID` = VALUES(`visibilityQuestID`),
    `visibilityQuestState` = VALUES(`visibilityQuestState`);
