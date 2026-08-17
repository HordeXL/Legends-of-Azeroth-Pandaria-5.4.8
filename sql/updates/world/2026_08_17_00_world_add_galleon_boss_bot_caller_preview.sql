-- First non-mutating world-boss caller stage.
-- One shared caller template is spawned near Galleon. Its explicit spawn-GUID
-- mapping permits candidate previews and status only; real bot login, grouping,
-- equipment, movement and combat remain locked until the encounter strategy and
-- reversible coordinator lifecycle have been implemented and tested.

CREATE TABLE IF NOT EXISTS `playerbot_world_boss_caller` (
  `guid` INT UNSIGNED NOT NULL COMMENT 'creature.guid of the caller',
  `boss_entry` MEDIUMINT UNSIGNED NOT NULL,
  `boss_search_radius` FLOAT UNSIGNED NOT NULL DEFAULT 250,
  `raid_size_mask` TINYINT UNSIGNED NOT NULL DEFAULT 3 COMMENT '1=10 player, 2=25 player',
  `strategy_ready` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `rally_x` FLOAT NOT NULL DEFAULT 0,
  `rally_y` FLOAT NOT NULL DEFAULT 0,
  `rally_z` FLOAT NOT NULL DEFAULT 0,
  `rally_o` FLOAT NOT NULL DEFAULT 0,
  `comment` VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`guid`),
  KEY `idx_boss_entry` (`boss_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Explicit playerbot world-boss caller site configuration';

DROP TEMPORARY TABLE IF EXISTS `_tmp_world_boss_bot_caller_template`;
CREATE TEMPORARY TABLE `_tmp_world_boss_bot_caller_template` LIKE `creature_template`;
INSERT INTO `_tmp_world_boss_bot_caller_template`
SELECT * FROM `creature_template` WHERE `entry` = 900100;

UPDATE `_tmp_world_boss_bot_caller_template`
SET `entry` = 990912,
    `name` = 'Boss Bot Caller',
    `femaleName` = 'Boss Bot Caller',
    `subname` = 'Galleon Raid Coordinator',
    `IconName` = '',
    `gossip_menu_id` = 0,
    `minlevel` = 90,
    `maxlevel` = 90,
    `faction` = 35,
    `npcflag` = 1,
    `npcflag2` = 0,
    `unit_flags` = 2,
    `unit_flags2` = 0,
    `dynamicflags` = 0,
    `AIName` = '',
    `MovementType` = 0,
    `flags_extra` = 2,
    `ScriptName` = 'npc_world_boss_bot_caller',
    `VerifiedBuild` = 18414;

REPLACE INTO `creature_template`
SELECT * FROM `_tmp_world_boss_bot_caller_template`;
DROP TEMPORARY TABLE `_tmp_world_boss_bot_caller_template`;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 990912;
INSERT INTO `creature_template_model`
    (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`)
VALUES
    (990912,0,41907,1,1,18414);

DELETE FROM `creature` WHERE `guid` = 4000096;
INSERT INTO `creature`
    (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,
     `modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,
     `spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,`curhealth`,
     `curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,`unit_flags2`,
     `dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`)
VALUES
    (4000096,990912,870,5805,6387,1,1,0,0,
     0,0,-653.000,-71.7403,155.839,5.9119,
     300,0,0,0,1,
     0,0,0,0,0,0,
     0,'',0,18414);

REPLACE INTO `playerbot_world_boss_caller`
    (`guid`,`boss_entry`,`boss_search_radius`,`raid_size_mask`,`strategy_ready`,
     `rally_x`,`rally_y`,`rally_z`,`rally_o`,`comment`)
VALUES
    (4000096,62346,150,3,0,
     -653.000,-71.7403,155.839,5.9119,
     'Galleon preview-only caller; Call remains locked until strategy audit');

