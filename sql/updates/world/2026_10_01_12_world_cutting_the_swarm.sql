-- Cutting the Swarm (30898)
--
-- The battlefield contained only the non-interactive Dragon Launcher prop
-- (61746).  The actual launcher vehicle (62024, VehicleId 2216) was not
-- spawned and had no spell-click data, so players could not enter it or use
-- its two vehicle abilities (120707/120706).
--
-- The swarm itself had also been reduced to one static Krik'thik Drone with
-- a one-minute respawn.  Restore enough targets in front of the launchers for
-- the intended artillery sequence instead of making players camp respawns.

START TRANSACTION;

-- Turn the existing launcher props on the Sik'vess battlefront into the
-- client-defined launcher vehicle while preserving their exact placement.
UPDATE `creature`
SET `id`=62024
WHERE `id`=61746 AND `map`=870 AND `areaId`=6187;

UPDATE `creature_template`
SET `npcflag`=`npcflag` | 16777216,
    `IconName`='vehichlecursor'
WHERE `entry`=62024;

DELETE FROM `npc_spellclick_spells`
WHERE `npc_entry`=62024 AND `spell_id`=46598;

INSERT INTO `npc_spellclick_spells`
(`npc_entry`,`spell_id`,`cast_flags`,`user_type`) VALUES
(62024,46598,1,0);

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId`=18
  AND `SourceGroup`=62024 AND `SourceEntry`=46598;

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
 `ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,
 `ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`) VALUES
(18,62024,46598,0,0,9,0,30898,0,0,0,0,0,'',
 'Dragon Launcher - Spell click requires Cutting the Swarm active');

-- Keep the original retail target, but make a killed drone return promptly.
UPDATE `creature`
SET `spawntimesecs`=5, `spawntimesecs_max`=5
WHERE `id`=61960 AND `map`=870 AND `areaId`=6187;

-- Idempotency for development databases where this migration may be replayed.
DELETE FROM `creature`
WHERE `id`=61960 AND `map`=870 AND `areaId`=6187
  AND `VerifiedBuild`=-2026100112;

-- Restore the missing swarm in the open field below the launchers.  These
-- positions follow the existing battlefront population and use short random
-- movement so targets remain spread out inside the artillery firing arc.
INSERT INTO `creature`
(`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,
 `modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,
 `spawntimesecs`,`spawntimesecs_max`,`wander_distance`,`currentwaypoint`,
 `curhealth`,`curmana`,`MovementType`,`npcflag`,`npcflag2`,`unit_flags`,
 `unit_flags2`,`dynamicflags`,`ScriptName`,`walk_mode`,`VerifiedBuild`) VALUES
(61960,870,5842,6187,1,1,0,0,0,0,1191.0,2788.0,268.8,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1201.0,2801.0,266.9,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1213.0,2811.0,264.9,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1230.0,2798.0,263.1,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1242.0,2810.0,263.3,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1255.0,2804.0,263.7,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1190.0,2838.0,268.0,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1206.0,2828.0,266.0,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1220.0,2842.0,264.4,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1236.0,2835.0,264.1,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1250.0,2823.0,264.2,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1258.0,2848.0,262.0,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1184.0,2861.0,270.0,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1200.0,2869.0,274.0,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1217.0,2860.0,266.0,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1234.0,2852.0,264.4,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1260.0,2820.0,265.8,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1270.0,2808.0,266.8,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112),
(61960,870,5842,6187,1,1,0,0,0,0,1270.0,2835.0,268.0,0.0,5,5,8,0,1,0,1,0,0,0,0,0,'',0,-2026100112);

COMMIT;
