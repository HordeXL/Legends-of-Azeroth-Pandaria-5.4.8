-- Restore the two legacy alternate-phase quest 29792 gate spawns removed by
-- 2026_07_14_05_world_quest_29792_remove_legacy_phase_gate_duplicates.sql.
INSERT INTO `gameobject`
(`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,`VerifiedBuild`)
VALUES
(539997,211283,860,5736,5737,1,4096,0,0,566.524,3583.47,92.1576,3.14,0,0,0,1,0,100,0,'',0),
(540346,211282,860,5736,5828,1,2048,0,0,695.26,3600.99,142.381,3.04,0,0,0,1,0,100,0,'',0);
