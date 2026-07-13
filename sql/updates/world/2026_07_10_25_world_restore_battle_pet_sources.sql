-- Restore the eleven wild battle-pet source spawns removed by
-- 2026_07_03_00_world_startup_error_cleanup.sql.
-- Exact pre-cleanup rows come from:
-- C:/Users/Admin/Desktop/world_bt_updates_before_20260703_145145.sql
-- The core now falls back to DB/home coordinates when the live Z is invalid.
-- Never overwrite a GUID that has since been reused.

INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
SELECT 237571,49842,1,331,2457,1,1,0,0,36956,0,2394.12,-2971.93,124.712,3.89042,300,0,0,0,8,0,0,0,0,0,0,0,'',0,0
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `guid`=237571);

INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
SELECT 240095,49842,1,331,331,1,1,0,0,36944,0,2961.4,-888.028,200.649,3.84461,300,0,0,0,8,0,0,0,0,0,0,0,'',0,0
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `guid`=240095);

INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
SELECT 240186,49842,1,331,331,1,1,0,0,36957,0,3498.01,359.272,4.37368,2.78659,300,0,0,0,8,0,0,0,0,0,0,0,'',0,0
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `guid`=240186);

INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
SELECT 240214,49842,1,331,2301,1,1,0,0,36957,0,3354.31,-362.527,141.667,1.46402,300,0,0,0,8,0,2,0,0,0,0,0,'',0,0
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `guid`=240214);

INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
SELECT 240261,49842,1,331,2301,1,1,0,0,36952,0,3059.29,-49.105,92.1495,1.00704,300,0,0,0,8,0,2,0,0,0,0,0,'',0,0
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `guid`=240261);

INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
SELECT 240384,49842,1,331,331,1,1,0,0,36952,0,2479.7,-2.10493,89.6869,5.78701,300,0,0,0,8,0,0,0,0,0,0,0,'',0,0
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `guid`=240384);

INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
SELECT 527565,63980,870,6138,6346,1,1,0,0,0,0,817.348,3769.47,243.004,5.48192,300,0,5,0,1,0,1,0,0,0,0,0,'',0,0
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `guid`=527565);

INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
SELECT 527567,63980,870,6138,6346,1,1,0,0,0,0,832.597,3797.34,236.391,4.41147,300,0,5,0,1,0,1,0,0,0,0,0,'',0,0
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `guid`=527567);

INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
SELECT 527568,63980,870,6138,6346,1,1,0,0,0,0,852.932,3770.53,240.183,1.28574,300,0,5,0,1,0,1,0,0,0,0,0,'',0,0
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `guid`=527568);

INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
SELECT 527577,63980,870,6138,6346,1,1,0,0,0,0,801.915,3797.23,238.197,2.88531,300,0,5,0,1,0,1,0,0,0,0,0,'',0,0
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `guid`=527577);

INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
SELECT 527582,63980,870,6138,6346,1,1,0,0,0,0,849.24,3788.81,238.555,6.14235,300,0,5,0,1,0,1,0,0,0,0,0,'',0,0
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `guid`=527582);

-- Only these two source creatures had addon rows in the pre-cleanup backup.
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`MountCreatureID`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`)
SELECT 240214,240214,0,0,0,3,0,1,0,0,0,0,0,0,NULL
WHERE EXISTS (SELECT 1 FROM `creature` WHERE `guid`=240214 AND `id`=49842)
  AND NOT EXISTS (SELECT 1 FROM `creature_addon` WHERE `guid`=240214);

INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`MountCreatureID`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`)
SELECT 240261,240261,0,0,0,3,0,1,0,0,0,0,0,0,NULL
WHERE EXISTS (SELECT 1 FROM `creature` WHERE `guid`=240261 AND `id`=49842)
  AND NOT EXISTS (SELECT 1 FROM `creature_addon` WHERE `guid`=240261);
