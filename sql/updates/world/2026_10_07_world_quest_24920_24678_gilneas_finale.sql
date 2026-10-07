-- Gilneas finale fixes: Quest 24920 "Slowing the Inevitable" (拖延不可避免的局势)
-- bat flight & bombing run + Quest 24678 "Knee-Deep" (深可及膝) tunnel turn-in.
--
-- Merged from 2026_10_07_world_quest_24920_bat_flight_bombing.sql and
-- 2026_10_07_world_quest_24678_knee_deep_turnin.sql - net final state.
-- All statements idempotent-safe and already applied to the live DB.

-- ===========================================================================
-- Part 1 - Quest 24920: bat flight & bombing run
-- ===========================================================================
-- Official mechanic: clicking the Captured Riding Bat (38615) casts 72472,
-- a summon spell (SummonProperties 161, Category=4 VEHICLE) that spawns the
-- flying bat 38540 and auto-rides the clicker via 46598. The bat then flies
-- the bombing-run path; reaching the end removes the ride aura (return to camp).
--
-- SAI note: only row 0 (RESPAWN -> WP_START) starts the flight. Do NOT add a
-- SPELLHIT(46598) -> WP_START row: StartPath() from the spellhit calls
-- StopPath() -> EndPath(), which fires WAYPOINT_ENDED and removes aura 46598,
-- instantly ejecting the just-boarded player ("vehicle appears then vanishes").
--
-- 38540 must NOT have a static spawn: it is a pure summon of 72472. A static
-- one would loop around the camp forever.
--
-- Faction 1934 (not 35): fgroup 2 => hostile to Forsaken Invaders (group 4);
-- explicit enemies [960] => hostile to the 1771 catapults; friendgrp 2 =>
-- friendly to the player, so the Iron Bomb impact (72247, 32yd enemy-only AoE
-- after DBC retarget, preserved 2609 one-shot damage) can never hit the rider.
--
-- Bomb ground impact: the Iron Bomb cast (72246) triggered its impact spell
-- (72247) at the caster position - the bat flies ~25-60yd up, so bombs
-- exploded in mid-air and never damaged the ground objectives (no quest
-- credit either). Fix: SpellEffect.dbc 72246 TargetA TARGET_DEST_DEST(87) ->
-- TARGET_DEST_CASTER(18) (DBC patch on the F: drive, SpellEffect.dbc row
-- 72950), plus the spell_q24920_iron_bomb SpellScript (zone_gilneas.cpp) that
-- relocates the dest to the ground directly below the caster; the triggered
-- impact spell inherits the dest. Damage values are untouched.
--
-- Forsaken Invaders targetable: creature_template 38363 (416 spawns along the
-- battle front) carried UNIT_FLAG_NOT_SELECTABLE (0x02000000) in unit_flags:
-- the client could not mouse-select them and the bomb AoE (72247) skipped them
-- entirely. Strip the flag, keep CAN_SWIM (0x8000). Catapults (38287) and
-- Plaguesmiths (38364) have clean flags already.

-- flying bat 38540: bomb spell on spell2, bomb-friendly faction, one-shot HP
UPDATE `creature_template` SET `spell2` = 72849, `faction` = 1934, `Health_mod` = 1 WHERE `entry` = 38540;

-- 38540 is a pure summon of 72472 - no static spawn
DELETE FROM `creature` WHERE `guid` = 9001720;

-- no duplicate flight start on boarding spellhit (see SAI note above)
DELETE FROM `smart_scripts` WHERE `entryorguid` = 38540 AND `source_type` = 0 AND `id` = 2;

-- 36-point bombing-run path: camp -> Forsaken lines -> back to camp
DELETE FROM `waypoint_data` WHERE `id` = 38540;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_flag`,`action`,`action_chance`,`wpguid`) VALUES
-- go to battle
(38540, 1, -1663.25, 1621.879, 25.96168, 0, 0, 0, 0, 100, 0),
(38540, 2, -1637.625, 1617.241, 33.15612, 0, 0, 0, 0, 100, 0),
(38540, 3, -1595.771, 1606.172, 44.07281, 0, 0, 0, 0, 100, 0),
(38540, 4, -1545.931, 1598.307, 44.07281, 0, 0, 0, 0, 100, 0),
(38540, 5, -1448.483, 1587.66, 44.07281, 0, 0, 0, 0, 100, 0),
(38540, 6, -1395.726, 1615.543, 44.07281, 0, 0, 0, 0, 100, 0),
(38540, 7, -1319.311, 1680.958, 44.07281, 0, 0, 0, 0, 100, 0),
-- bombing loop over the Forsaken lines
(38540, 8, -1241.325, 1747.767, 53.76252, 0, 0, 0, 0, 100, 0),
(38540, 9, -1186.814, 1708.936, 53.76252, 0, 0, 0, 0, 100, 0),
(38540, 10, -1107.872, 1646.177, 53.76252, 0, 0, 0, 0, 100, 0),
(38540, 11, -1056.335, 1608.783, 53.76252, 0, 0, 0, 0, 100, 0),
(38540, 12, -984.1858, 1623.411, 64.90141, 0, 0, 0, 0, 100, 0),
(38540, 13, -960.5712, 1668.052, 69.84588, 0, 0, 0, 0, 100, 0),
(38540, 14, -919.2639, 1708.543, 90.70698, 0, 0, 0, 0, 100, 0),
(38540, 15, -859.6215, 1700.193, 90.70698, 0, 0, 0, 0, 100, 0),
(38540, 16, -864.6215, 1626.049, 90.70698, 0, 0, 0, 0, 100, 0),
(38540, 17, -887.007, 1510.622, 90.70698, 0, 0, 0, 0, 100, 0),
(38540, 18, -950.3246, 1506.309, 82.34586, 0, 0, 0, 0, 100, 0),
(38540, 19, -1025.245, 1428.929, 74.51246, 0, 0, 0, 0, 100, 0),
(38540, 20, -1077.819, 1401.005, 58.4569, 0, 0, 0, 0, 100, 0),
(38540, 21, -1143.061, 1407.379, 51.04022, 0, 0, 0, 0, 100, 0),
(38540, 22, -1197.042, 1471.483, 47.34577, 0, 0, 0, 0, 100, 0),
(38540, 23, -1269.991, 1510.726, 47.34577, 0, 0, 0, 0, 100, 0),
(38540, 24, -1352.618, 1566.734, 47.34577, 0, 0, 0, 0, 100, 0),
(38540, 25, -1379.911, 1681.13, 47.34577, 0, 0, 0, 0, 100, 0),
(38540, 26, -1304.021, 1763.345, 54.04024, 0, 0, 0, 0, 100, 0),
(38540, 27, -1277.788, 1762.722, 55.95692, 0, 0, 0, 0, 100, 0),
-- back to the camp (parking spot next to clickable bat 38615)
(38540, 28, -1304.236, 1650.365, 64.76084, 0, 0, 0, 0, 100, 0),
(38540, 29, -1410.293, 1638.58, 37.38527, 0, 0, 0, 0, 100, 0),
(38540, 30, -1491.441, 1632.97, 32.0797, 0, 0, 0, 0, 100, 0),
(38540, 31, -1578.608, 1633.108, 32.0797, 0, 0, 0, 0, 100, 0),
(38540, 32, -1621.252, 1625.786, 29.66303, 0, 0, 0, 0, 100, 0),
(38540, 33, -1637.115, 1616.464, 28.71857, 0, 0, 0, 0, 100, 0),
(38540, 34, -1657.575, 1619.925, 25.35749, 0, 0, 0, 0, 100, 0),
(38540, 35, -1665.67, 1630.521, 25.35749, 0, 0, 0, 0, 100, 0),
(38540, 36, -1667.727, 1662.474, 22.60748, 0, 0, 0, 0, 100, 0);

-- Iron Bomb (72246) -> ground impact SpellScript (zone_gilneas.cpp)
DELETE FROM `spell_script_names` WHERE `spell_id` = 72246;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(72246, 'spell_q24920_iron_bomb');

-- Forsaken Invaders 38363 selectable by bomb AoE (strip NOT_SELECTABLE)
UPDATE `creature_template` SET `unit_flags` = 32768 WHERE `entry` = 38363;

-- ===========================================================================
-- Part 2 - Quest 24678: tunnel-exit turn-in NPC
-- ===========================================================================
-- Official mechanic: King Genn Greymane (38539, camp by the tunnel entrance)
-- provides the Half-Burnt Torch (50220, use spell 70631 keeps Graveyard Rats
-- at bay). The player descends the stairs behind Genn into the sewer tunnel
-- beneath Gilneas City, fights through rats/spiders/maggots, and the quest
-- completes on TURN-IN: "Speak to Krennan on the other side" - quest 24678
-- has no kill/collect objectives (quest_objective empty), credit is granted
-- when the player talks to Krennan Aranas (38144) at the tunnel exit.
--
-- Root cause of "no turn-in NPC at the other end": our 24904 battle SQL
-- (2026_10_07_00_world_quest_24904_official_battle_flow.sql, section 6)
-- relocated the ONLY spawn of 38144 (guid 219336) to the plaza staging point
-- (-1690, 1630, 20.6) as the battle starter. Retail keeps that city spawn AND
-- a tunnel-exit spawn (mmo4ever: 38144 found in both Gilneas City and
-- Gilneas; the exit camp also serves turn-ins of 24602 Laid to Rest and
-- 24679 Patriarch's Blessing). With only the plaza spawn, players exiting the
-- tunnel at the north end found nobody to turn in to.
--
-- Fix: keep guid 219336 in the plaza (24904 battle starter, signed off) and
-- add a second 38144 spawn at the tunnel-exit camp. Position = the shared
-- turn-in POI of 24678/24602/24679 (-1728, 1872); Z = 17.83 read from the
-- extracted map heightmap (0654_35_28.map, calibrated against the spirit
-- healer at (-1720.7, 1903.5, 18.58) and other outdoor anchors, error < 0.1).
-- Facing = toward the tunnel mouth (-1720, 1852). Phasemask 0x7E540F = city
-- phase union | 1, same as the plaza spawn, so he is visible both inside the
-- city phase (0x7E540E) and outside where players may drop to phasemask 1.
-- Requires server restart to load the new spawn row.

INSERT INTO `creature`
(`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `phaseId`, `phaseGroup`,
 `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`,
 `spawntimesecs`, `spawntimesecs_max`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`,
 `MovementType`, `npcflag`, `npcflag2`, `unit_flags`, `unit_flags2`, `dynamicflags`, `walk_mode`)
VALUES
(9001721, 38144, 654, 4714, 4727, 1, 8279055, 0, 0,
 29301, 0, -1728.0, 1872.0, 17.83, 5.09,
 60, 0, 0, 0, 186, 191,
 0, 0, 0, 0, 0, 0, 0);
