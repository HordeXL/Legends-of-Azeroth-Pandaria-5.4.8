-- Restore exact creature spawns from matching SkyFire 5.4.8 SFDB.
-- Source schema fields were mapped explicitly; current-only fields use neutral
-- defaults. Never overwrite a GUID that has since been reused.

INSERT INTO `creature`
(`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,
 `modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,
 `spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,
 `curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,
 `unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
SELECT
 77232,22044,530,0,0,1,1,0,0,0,0,1392.06,6845.37,107.352,5.00455,
 300,0,5,0,5914,0,1,0,0,0,0,0,'',0,0
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `guid`=77232);

INSERT INTO `creature`
(`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,
 `modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,
 `spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,
 `curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,
 `unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
SELECT
 136675,32923,603,0,0,8,1,0,0,28580,0,2199.07,-267.828,447.077,3.07178,
 180,0,0,0,18900,0,0,0,0,0,0,0,'',0,0
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `guid`=136675);
