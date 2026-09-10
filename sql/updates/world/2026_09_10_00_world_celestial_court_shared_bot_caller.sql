-- Shared Celestial Court caller at Grotroz's saved requested location.
-- boss_entry=0 means select the single attackable Chi-Ji/Xuen/Niuzao/Yu'lon.
-- Requires the matching caller code; apply with the new worldserver build.
-- Existing boss-specific callers are preserved. Reserved spawn GUID: 4000118.

START TRANSACTION;

INSERT INTO `creature`
    (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,
     `modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,
     `spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,
     `curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,
     `dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
SELECT 4000118,990912,870,6757,6830,1,4294967295,0,0,
       0,0,-750.005,-5016.65,-6.27724,0.0679426,
       300,0,0,0,1,0,0,0,0,0,0,0,'',0,18414
FROM `creature_template` t
WHERE t.`entry`=990912 AND t.`ScriptName`='npc_world_boss_bot_caller'
  AND NOT EXISTS (SELECT 1 FROM `creature` WHERE `guid`=4000118);

INSERT INTO `playerbot_world_boss_caller`
    (`guid`,`boss_entry`,`boss_search_radius`,`raid_size_mask`,`strategy_ready`,
     `rally_x`,`rally_y`,`rally_z`,`rally_o`,`comment`)
SELECT c.`guid`,0,250,3,1,-750.005,-5016.65,-6.27724,0.0679426,
       'Shared Celestial Court; active boss selected at Call; Grotroz saved location 2026-09-10'
FROM `creature` c
JOIN `creature_template` t ON t.`entry`=c.`id`
WHERE c.`guid`=4000118 AND c.`id`=990912 AND c.`map`=870
  AND t.`ScriptName`='npc_world_boss_bot_caller'
  AND ABS(c.`position_x`+750.005)<0.001
  AND ABS(c.`position_y`+5016.65)<0.001
  AND ABS(c.`position_z`+6.27724)<0.001
  AND ABS(c.`orientation`-0.0679426)<0.00001
ON DUPLICATE KEY UPDATE
    `boss_entry`=VALUES(`boss_entry`),
    `boss_search_radius`=VALUES(`boss_search_radius`),
    `raid_size_mask`=VALUES(`raid_size_mask`),
    `strategy_ready`=VALUES(`strategy_ready`),
    `rally_x`=VALUES(`rally_x`),`rally_y`=VALUES(`rally_y`),
    `rally_z`=VALUES(`rally_z`),`rally_o`=VALUES(`rally_o`),
    `comment`=VALUES(`comment`);

COMMIT;
