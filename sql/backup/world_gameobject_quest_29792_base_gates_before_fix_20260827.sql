-- Restore the exact phase-2 base gate rows removed by
-- 2026_08_27_00_world_quest_29792_remove_base_gate_duplicates.sql.

INSERT INTO `gameobject`
(`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`)
VALUES
(540026,210964,860,5736,5737,1,2,0,0,566.524,3583.47,92.1576,3.14,0,0,0,1,0,100,1,'',0),
(540359,210965,860,5736,5828,1,2,0,0,695.26,3600.99,142.381,3.04,0,0,0,1,0,100,1,'',0);

INSERT INTO `object_visibility_state`
    (`type`, `entryorguid`, `visibilityQuestID`, `visibilityQuestState`)
VALUES
    ('GameObject', -540359, 29792, 0),
    ('GameObject', -540026, 29792, 0)
ON DUPLICATE KEY UPDATE
    `visibilityQuestID` = VALUES(`visibilityQuestID`),
    `visibilityQuestState` = VALUES(`visibilityQuestState`);
