-- Implement the jade cart ride for quest 29930 "What's Mined Is Yours".
--
-- Blizzard flow: Hao Mann (56467) offers the quest next to a jade cart; the
-- player clicks the cart, rides on the back while Hao drives it from the
-- Greenstone Quarry to Emperor's Omen, and the objective (256124: MONSTER /
-- ObjectID 56508 Jade Cart / Amount 1) is credited on arrival.  Foreman Mann
-- (56346) at Emperor's Omen takes the turn-in.
--
-- The cart entity existed as a template (56508 "Jade Cart", model 40778) but
-- was completely unimplemented: no spawn, no vehicle, no spell click, no AI,
-- and the objective therefore had no credit source at all.
--
-- Path: 36 points sampled from the real terrain height map
-- (Data/maps/0870_27_35.map, GridMap V9/V8 triangle interpolation), following
-- the Blizzard taxi trail nodes that run past the quarry towards Emperor's
-- Omen (TaxiPathNode trails of nodes 888/895 -> 970) and the flat corridor
-- south of the Omen (z stays within 218-235, max slope ~0.4).
--
-- Requires a worldserver restart (creature, creature_template, waypoint_data,
-- npc_spellclick_spells and smart_scripts are all loaded at startup).

-- 1) Cart ride path.  NOTE: SmartAI's StartPath() reads the `waypoints` table
--    (SmartWaypointMgr), NOT `waypoint_data` - the latter is only for
--    MovementType 2 static patrols and would never be found by the script.
DELETE FROM `waypoints` WHERE `entry` = 56508;
-- (cleanup: an earlier revision wrongly put this path into `waypoint_data`)
DELETE FROM `waypoint_data` WHERE `id` = 56508;
INSERT INTO `waypoints` (`entry`, `pointid`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `point_comment`) VALUES
(56508, 1, 2268, -1779, 235.06, 4.209, 0, NULL),
(56508, 2, 2261.31, -1791.14, 235.25, 4.209, 0, NULL),
(56508, 3, 2254.62, -1803.29, 234.86, 4.209, 0, NULL),
(56508, 4, 2247.93, -1815.43, 234.18, 4.209, 0, NULL),
(56508, 5, 2241.24, -1827.58, 232.84, 4.209, 0, NULL),
(56508, 6, 2234.56, -1839.72, 231.3, 4.209, 0, NULL),
(56508, 7, 2227.87, -1851.87, 229.41, 4.209, 0, NULL),
(56508, 8, 2221.18, -1864.01, 227.09, 4.209, 0, NULL),
(56508, 9, 2214.49, -1876.16, 224.87, 4.209, 0, NULL),
(56508, 10, 2207.8, -1888.3, 221.98, 3.944, 0, NULL),
(56508, 11, 2197.75, -1898.7, 219.2, 3.944, 0, NULL),
(56508, 12, 2187.7, -1909.1, 218.63, 5.270, 0, NULL),
(56508, 13, 2194.85, -1920.56, 219.01, 5.270, 0, NULL),
(56508, 14, 2202, -1932.02, 219.29, 5.270, 0, NULL),
(56508, 15, 2209.15, -1943.48, 220.55, 5.270, 0, NULL),
(56508, 16, 2216.3, -1954.94, 222.03, 5.270, 0, NULL),
(56508, 17, 2223.45, -1966.4, 222.4, 5.270, 0, NULL),
(56508, 18, 2230.6, -1977.86, 222.02, 5.270, 0, NULL),
(56508, 19, 2237.75, -1989.32, 221.62, 5.270, 0, NULL),
(56508, 20, 2244.9, -2000.78, 222.01, 5.270, 0, NULL),
(56508, 21, 2252.05, -2012.24, 223.26, 5.270, 0, NULL),
(56508, 22, 2259.2, -2023.7, 223.77, 5.529, 0, NULL),
(56508, 23, 2269.4, -2033.28, 223.14, 5.530, 0, NULL),
(56508, 24, 2279.6, -2042.85, 222.56, 5.529, 0, NULL),
(56508, 25, 2289.8, -2052.43, 222.37, 5.530, 0, NULL),
(56508, 26, 2300, -2062, 222.5, 5.253, 0, NULL),
(56508, 27, 2307.5, -2074.5, 222.99, 5.253, 0, NULL),
(56508, 28, 2315, -2087, 222.25, 5.253, 0, NULL),
(56508, 29, 2322.5, -2099.5, 222.55, 5.253, 0, NULL),
(56508, 30, 2330, -2112, 228.37, 6.184, 0, NULL),
(56508, 31, 2345, -2113.5, 234.53, 6.184, 0, NULL),
(56508, 32, 2360, -2115, 235.06, 6.184, 0, NULL),
(56508, 33, 2375, -2116.5, 231.57, 6.184, 0, NULL),
(56508, 34, 2390, -2118, 228.68, 1.066, 0, NULL),
(56508, 35, 2395.2, -2108.6, 228.51, 1.066, 0, NULL),
(56508, 36, 2400.4, -2099.2, 228.11, 0.000, 0, NULL);

-- 2) Spawn the cart next to Hao Mann (56467 at 2271.45, -1772.63, 234.04).
DELETE FROM `creature` WHERE `guid` = 4000119;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `phaseId`, `phaseGroup`, `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `spawntimesecs_max`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `npcflag2`, `unit_flags`, `unit_flags2`, `dynamicflags`, `ScriptName`, `walk_mode`, `VerifiedBuild`) VALUES
(4000119, 56508, 870, 0, 0, 1, 1, 0, 0, 0, 0, 2268, -1779, 235.06, 4.209, 30, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, '', 0, 0);

-- 3) Make the cart a rideable vehicle that players can click
--    (UNIT_NPC_FLAG_SPELLCLICK = 0x01000000).  VehicleId 2217 is the "cart"
--    vehicle used by the other Pandaria cart (Ji-Lu's Cart 60094); its two
--    seats have no "can control" flag, so the boarded player is a pure
--    passenger and cannot fight the scripted drive.
UPDATE `creature_template` SET `VehicleId` = 2217, `npcflag` = 16777216, `AIName` = 'SmartAI' WHERE `entry` = 56508;

-- 4) Spell click -> ride the cart (46598 "Ride Vehicle Hardcoded", seat 0).
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` = 56508;
INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`) VALUES
(56508, 46598, 1, 0);

-- 5) SmartAI: when a passenger boards, remember that player
--    (SMART_ACTION_STORE_TARGET_LIST 64 on the boarded rider) and start the
--    ride; when the path ends, credit that remembered rider
--    (CALL_KILLEDMONSTER 56508 on SMART_TARGET_STORED 12) and despawn the cart
--    so the rider dismounts.  Crediting the stored rider avoids depending on
--    the vehicle seat index (SMART_TARGET_VEHICLE_ACCESSORY 29 did not find
--    the passenger in practice).
DELETE FROM `smart_scripts` WHERE `entryorguid` = 56508 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(56508, 0, 0, 0, 27, 0, 100, 0, 0, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Passenger boarded - remember the rider'),
(56508, 0, 1, 0, 27, 0, 100, 0, 0, 0, 0, 0, 0, 53, 1, 56508, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Passenger boarded - start the jade cart ride'),
(56508, 0, 2, 0, 58, 0, 100, 0, 0, 56508, 0, 0, 0, 33, 56508, 0, 0, 0, 0, 0, 12, 1, 0, 0, 0, 0, 0, 0, 0, 'Waypoint ended - credit the rider'),
(56508, 0, 3, 0, 58, 0, 100, 0, 0, 56508, 0, 0, 0, 41, 3000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Waypoint ended - despawn the cart');
