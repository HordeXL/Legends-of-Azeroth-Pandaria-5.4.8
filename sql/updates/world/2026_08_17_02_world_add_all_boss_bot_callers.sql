-- Add one neutral Boss Bot Caller at every locally spawned supported Pandaria
-- world-boss site. Sha of Anger receives one caller at each of its five spawn
-- positions. These rows enable guarded login/group/summon staging only; combat
-- strategies and temporary PvE equipment are audited in later updates.

UPDATE `creature_template`
SET `subname` = 'Pandaria Raid Coordinator'
WHERE `entry` = 990912
  AND `ScriptName` = 'npc_world_boss_bot_caller';

INSERT INTO `creature`
    (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,
     `modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,
     `spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,
     `curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,
     `dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
VALUES
    -- Sha of Anger: five possible spawn sites.
    (4000097,990912,870,5841,6415,1,1,0,0,0,0,1983.730,1634.280,482.576,3.633,300,0,0,0,1,0,0,0,0,0,0,0,'',0,18414),
    (4000098,990912,870,5841,6415,1,1,0,0,0,0,2386.800, 595.601,494.394,4.033,300,0,0,0,1,0,0,0,0,0,0,0,'',0,18414),
    (4000099,990912,870,5841,6090,1,1,0,0,0,0,2762.450,1711.460,647.720,3.391,300,0,0,0,1,0,0,0,0,0,0,0,'',0,18414),
    (4000100,990912,870,5841,6090,1,1,0,0,0,0,2949.010,1476.000,648.314,0.444,300,0,0,0,1,0,0,0,0,0,0,0,'',0,18414),
    (4000101,990912,870,5841,6152,1,1,0,0,0,0,2980.400, 407.047,507.075,4.593,300,0,0,0,1,0,0,0,0,0,0,0,'',0,18414),
    -- Nalak and Oondasta.
    (4000102,990912,1064,6507,6593,1,1,0,0,0,0,7082.960,5168.820,120.566,5.478,300,0,0,0,1,0,0,0,0,0,0,0,'',0,18414),
    (4000103,990912,870,6661,6661,1,1,0,0,0,0,5980.870,1118.220, 56.495,2.850,300,0,0,0,1,0,0,0,0,0,0,0,'',0,18414),
    -- Timeless Isle Celestial Court and Ordos.
    (4000104,990912,870,6757,6830,1,1,0,0,0,0,-525.876,-4950.770,-6.277,0.780,300,0,0,0,1,0,0,0,0,0,0,0,'',0,18414),
    (4000105,990912,870,6757,6830,1,1,0,0,0,0,-765.804,-4955.080,-6.194,2.495,300,0,0,0,1,0,0,0,0,0,0,0,'',0,18414),
    (4000106,990912,870,6757,6830,1,1,0,0,0,0,-532.157,-5076.770,-6.277,5.430,300,0,0,0,1,0,0,0,0,0,0,0,'',0,18414),
    (4000107,990912,870,6757,6830,1,1,0,0,0,0,-767.969,-5080.940,-6.194,3.756,300,0,0,0,1,0,0,0,0,0,0,0,'',0,18414),
    (4000108,990912,870,6757,6823,1,1,0,0,0,0, -71.148,-5402.760,150.114,6.053,300,0,0,0,1,0,0,0,0,0,0,0,'',0,18414);

INSERT INTO `playerbot_world_boss_caller`
    (`guid`,`boss_entry`,`boss_search_radius`,`raid_size_mask`,`strategy_ready`,
     `rally_x`,`rally_y`,`rally_z`,`rally_o`,`comment`)
VALUES
    (4000097,60491,180,3,0,1983.730,1634.280,482.576,3.633,'Sha site 1; guarded staging enabled, strategy audit pending'),
    (4000098,60491,180,3,0,2386.800, 595.601,494.394,4.033,'Sha site 2; guarded staging enabled, strategy audit pending'),
    (4000099,60491,180,3,0,2762.450,1711.460,647.720,3.391,'Sha site 3; guarded staging enabled, strategy audit pending'),
    (4000100,60491,180,3,0,2949.010,1476.000,648.314,0.444,'Sha site 4; guarded staging enabled, strategy audit pending'),
    (4000101,60491,180,3,0,2980.400, 407.047,507.075,4.593,'Sha site 5; guarded staging enabled, strategy audit pending'),
    (4000102,69099,180,3,0,7082.960,5168.820,120.566,5.478,'Nalak; guarded staging enabled, strategy audit pending'),
    (4000103,69161,220,3,0,5980.870,1118.220, 56.495,2.850,'Oondasta; guarded staging enabled, strategy audit pending'),
    (4000104,71952,140,3,0,-525.876,-4950.770,-6.277,0.780,'Chi-Ji; guarded staging enabled, strategy audit pending'),
    (4000105,71953,140,3,0,-765.804,-4955.080,-6.194,2.495,'Xuen; guarded staging enabled, strategy audit pending'),
    (4000106,71954,140,3,0,-532.157,-5076.770,-6.277,5.430,'Niuzao; guarded staging enabled, strategy audit pending'),
    (4000107,71955,140,3,0,-767.969,-5080.940,-6.194,3.756,'Yu''lon; guarded staging enabled, strategy audit pending'),
    (4000108,72057,180,3,0, -71.148,-5402.760,150.114,6.053,'Ordos; guarded staging enabled, strategy audit pending')
ON DUPLICATE KEY UPDATE
    `boss_entry`=VALUES(`boss_entry`),
    `boss_search_radius`=VALUES(`boss_search_radius`),
    `raid_size_mask`=VALUES(`raid_size_mask`),
    `strategy_ready`=VALUES(`strategy_ready`),
    `rally_x`=VALUES(`rally_x`),
    `rally_y`=VALUES(`rally_y`),
    `rally_z`=VALUES(`rally_z`),
    `rally_o`=VALUES(`rally_o`),
    `comment`=VALUES(`comment`);

UPDATE `playerbot_world_boss_caller`
SET `comment`='Galleon; guarded staging enabled, strategy audit pending'
WHERE `guid`=4000096 AND `boss_entry`=62346;
