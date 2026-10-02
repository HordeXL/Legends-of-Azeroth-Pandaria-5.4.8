-- ============================================================
-- Consolidated fix: Quests 29680 (生计来源 / The Source of Our
-- Livelihood) and 29800 (新的盟友 / New Allies) - Delivery Cart rides
--
-- Merged from 2026_10_02_01 .. 2026_10_02_07 (iterative fixes).
-- Sections must run in order: later sections override earlier ones,
-- the final state matches the live world DB after all 7 fixes.
--
-- Final design (quest 29680 chain):
--   * Clickable carts 57710/57741 are vehicles (vehicleid 1944);
--     spellclick spell 46598 (Ride Vehicle, Control Vehicle aura 236).
--   * On boarding: Disable Move flag (0x4000) cleared, yak 57709
--     (guid 562165) runs its own lead path (5770900, 4.5 yd ahead),
--     the cart FOLLOWS the yak (dist 5, speed sync).
--   * At lead point 18 (Dai-Lo Farmstead): yak casts 50630 on the
--     cart -> passengers ejected; BOTH yak and cart Force Despawn
--     after 5s and respawn at their spawn coordinates.
--     Path 5770900 = 18 pts recorded in-game (CoordRecorder plugin,
--     SECTION 13). Backup trigger: yak WAYPOINT_ENDED (event 58).
--   * Cart 57741 (quest 29800) keeps its own path 5774000
--     (no yak spawn exists for it).
-- Requires: worldserver restart (waypoints + creature_template).
-- ============================================================


-- ############################################################
-- ## SECTION FROM: 2026_10_02_01_world_quest_29680_29800_delivery_cart.sql
-- ############################################################

-- ============================================================
-- Fix: Quests 29680 (生计来源 / The Source of Our Livelihood)
--      and 29800 (新的盟友 / New Allies) - Delivery Cart rides
--
-- Reference: TrinityCore master zone_the_wandering_isle.cpp
--            (Scripts::Pandaria::TheWanderingIsle::npc_delivery_cart)
--   Official design: player clicks the static cart (spellclick ->
--   Control Vehicle seat), PassengerBoarded starts the ride,
--   yak follows, at final waypoint passengers are ejected
--   (spell 50630), path end despawns the cart.
--
-- Problems fixed here:
--   1. Clickable carts 57710/57741 had vehicleid = 0, so the
--      spellclick seat spell (107784/108933) had no vehicle kit
--      to seat the player -> "right-click completes the counter
--      but nobody rides".
--   2. Objective descriptions were empty -> zhCN client showed
--      the default kill string "已杀死牛车".
--   3. No ride path / eject / despawn logic existed.
--
-- Waypoint paths are terrain-sampled from Data/maps/0860_*.map
-- (same height interpolation as GridMap::getHeight).
-- Path IDs follow the official naming: <vehicleEntry>00.
-- ============================================================

-- 1) Make the clickable quest carts real vehicles (Vehicle.dbc 1944)
UPDATE `creature_template`
SET `vehicleid` = 1944
WHERE `entry` IN (57710, 57741);

-- 2) Objective text fixes
UPDATE `quest_objective`
SET `description` = 'Ride the ox cart to the Dai-Lo Farmstead.'
WHERE `questId` = 29680 AND `objectId` = 57710;

UPDATE `quest_objective`
SET `description` = 'Ride the ox cart to the Temple of Five Dawns.'
WHERE `questId` = 29800 AND `objectId` = 57741;

DELETE FROM `quest_objectives_locale` WHERE `ID` IN (29680, 29800);
INSERT INTO `quest_objectives_locale`
    (`ID`, `locale`, `QuestId`, `StorageIndex`, `Description`, `VerifiedBuild`)
VALUES
    (29680, 'zhCN', 29680, 0, '乘坐牛车', 18414),
    (29800, 'zhCN', 29800, 0, '乘坐牛车', 18414);

-- 3) Ride path: Singing Pools cart (57710) -> Dai-Lo Farmstead (Ji)
DELETE FROM `waypoint_data` WHERE `id` = 5720800;
INSERT INTO `waypoint_data`
    (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `move_flag`, `action`, `action_chance`, `wpguid`)
VALUES
    (5720800,  1, 940.00, 2856.00,  80.20, 0, 0, 1, 0, 100, 0),
    (5720800,  2, 896.00, 2856.00,  80.20, 0, 0, 1, 0, 100, 0),
    (5720800,  3, 852.00, 2856.00,  80.20, 0, 0, 1, 0, 100, 0),
    (5720800,  4, 816.00, 2832.00,  86.30, 0, 0, 1, 0, 100, 0),
    (5720800,  5, 776.00, 2828.00,  82.90, 0, 0, 1, 0, 100, 0),
    (5720800,  6, 756.00, 2864.00,  75.50, 0, 0, 1, 0, 100, 0),
    (5720800,  7, 740.00, 2904.00,  75.10, 0, 0, 1, 0, 100, 0),
    (5720800,  8, 704.00, 2928.00,  75.90, 0, 0, 1, 0, 100, 0),
    (5720800,  9, 680.00, 2964.00,  75.40, 0, 0, 1, 0, 100, 0),
    -- bridge over the river gorge (deck height, not riverbed)
    (5720800, 10, 684.00, 3004.00,  79.50, 0, 0, 1, 0, 100, 0),
    (5720800, 11, 664.00, 3036.00,  79.50, 0, 0, 1, 0, 100, 0),
    (5720800, 12, 632.00, 3064.00,  80.40, 0, 0, 1, 0, 100, 0),
    (5720800, 13, 620.00, 3104.00,  87.80, 0, 0, 1, 0, 100, 0),
    (5720800, 14, 628.00, 3140.00,  88.30, 0, 0, 1, 0, 100, 0); -- Dai-Lo Farmstead (next to Ji)

-- 4) Ride path: Forest/Wreck cart (57741) -> Temple of Five Dawns
DELETE FROM `waypoint_data` WHERE `id` = 5774000;
INSERT INTO `waypoint_data`
    (`id`, `point`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `move_flag`, `action`, `action_chance`, `wpguid`)
VALUES
    (5774000,  1, 312.00, 3872.00,  78.80, 0, 0, 1, 0, 100, 0),
    (5774000,  2, 356.00, 3876.00,  78.60, 0, 0, 1, 0, 100, 0),
    (5774000,  3, 392.00, 3852.00,  78.40, 0, 0, 1, 0, 100, 0),
    (5774000,  4, 436.00, 3840.00,  78.60, 0, 0, 1, 0, 100, 0),
    (5774000,  5, 472.00, 3820.00,  76.80, 0, 0, 1, 0, 100, 0),
    (5774000,  6, 504.00, 3796.00,  79.10, 0, 0, 1, 0, 100, 0),
    (5774000,  7, 524.00, 3756.00,  79.60, 0, 0, 1, 0, 100, 0),
    (5774000,  8, 560.00, 3724.00,  83.40, 0, 0, 1, 0, 100, 0),
    (5774000,  9, 592.00, 3696.00, 101.20, 0, 0, 1, 0, 100, 0),
    (5774000, 10, 604.00, 3664.00, 115.60, 0, 0, 1, 0, 100, 0),
    (5774000, 11, 616.00, 3636.00, 129.80, 0, 0, 1, 0, 100, 0),
    (5774000, 12, 656.00, 3612.00, 146.30, 0, 0, 1, 0, 100, 0),
    (5774000, 13, 696.00, 3612.00, 144.00, 0, 0, 1, 0, 100, 0),
    (5774000, 14, 736.00, 3632.00, 141.10, 0, 0, 1, 0, 100, 0),
    (5774000, 15, 772.00, 3660.00, 141.30, 0, 0, 1, 0, 100, 0),
    (5774000, 16, 784.00, 3648.00, 158.30, 0, 0, 1, 0, 100, 0),
    (5774000, 17, 824.00, 3632.00, 163.80, 0, 0, 1, 0, 100, 0); -- Temple of Five Dawns terrace

-- 5) SAI: Singing Pools cart 57710 (quest 29680)
--    Keeps existing ids 0-1 (rope visuals on respawn); adds the ride chain.
DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = 57710 AND `id` >= 2;
DELETE FROM `smart_scripts`
WHERE `source_type` = 9 AND `entryorguid` = 5771001;
DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = -562165;

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    -- passenger boards the cart -> run ride script
    (57710, 0, 2, 0, 27, 0, 100, 0, 0, 0, 0, 0, 0,
     80, 5771001, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - On Passenger Boarded - Start Ride Script'),
    -- reached final waypoint -> eject passengers (official spell 50630)
    (57710, 0, 3, 0, 40, 0, 100, 0, 14, 5720800, 0, 0, 0,
     11, 50630, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - Reached Final Point - Eject Passengers'),
    -- path ended -> tell the yak to go home...
    (57710, 0, 4, 0, 58, 0, 100, 0, 0, 5720800, 0, 0, 0,
     45, 1, 1, 0, 0, 0, 0, 19, 57709, 15, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - Path Ended - Signal Yak To Go Home'),
    -- ...then despawn (respawns at spawn point after spawntimesecs)
    (57710, 0, 5, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0,
     41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - Path Ended - Despawn');

-- Ride script (timed action list): yak follows + rope visual + start path
INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (5771001, 9, 0, 0, 0, 0, 100, 0, 500, 500, 0, 0, 0,
     29, 1, 0, 0, 0, 0, 0, 19, 57709, 10, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - Nourished Yak Follows Cart'),
    (5771001, 9, 1, 0, 0, 0, 100, 0, 800, 800, 0, 0, 0,
     11, 108877, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - Cast Ox Cart Rope Left'),
    (5771001, 9, 2, 0, 0, 0, 100, 0, 1800, 1800, 0, 0, 0,
     53, 1, 5720800, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - Start Ride Path (run, no repeat)');

-- Yak goes back home when the cart signals it
INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (-562165, 0, 0, 0, 38, 0, 100, 0, 1, 0, 0, 0, 0,
     69, 1, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 979.37, 2860.29, 88.38, 0,
     'Nourished Yak - Cart Signal - Move Home');

-- 6) SAI: Forest/Wreck cart 57741 (quest 29800)
DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = 57741;

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (57741, 0, 0, 0, 27, 0, 100, 0, 0, 0, 0, 0, 0,
     53, 1, 5774000, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - On Passenger Boarded - Start Ride Path (run, no repeat)'),
    (57741, 0, 1, 0, 40, 0, 100, 0, 17, 5774000, 0, 0, 0,
     11, 50630, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - Reached Final Point - Eject Passengers'),
    (57741, 0, 2, 0, 58, 0, 100, 0, 0, 5774000, 0, 0, 0,
     41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - Path Ended - Despawn');


-- ############################################################
-- ## SECTION FROM: 2026_10_02_02_world_spellclick_ride_46598.sql
-- ############################################################

-- ============================================================
-- Fix (follow-up to 2026_10_02_01): player never boards the cart
--
-- Root cause (proven from Data/dbc/SpellEffect.dbc and core code):
--   Spellclick spells 107784/108933/114453 have NO effect with
--   SpellAuraName = 236 (SPELL_AURA_CONTROL_VEHICLE). Their real
--   function is "summon the vehicle cart creature" (Effect 28 ->
--   57208/57740/59496), i.e. the official two-step design
--   (static prop cart -> summoned vehicle cart).
--   In Unit::HandleSpellClick, a click on a creature that the
--   client treats as a vehicle requires the click spell to carry
--   the CONTROL_VEHICLE aura, otherwise the click is rejected
--   ("not a valid vehicle enter aura") and NOTHING happens.
--
--   In this fork's simplified single-creature design (the clicked
--   cart itself is the vehicle, vehicleid = 1944) the click spell
--   must therefore be a real "Ride Vehicle" spell.
--   Spell 46598 ("Ride Vehicle") has Effect 6 / Aura 236 with
--   TargetA = 25 (TARGET_UNIT_TARGET_ANY) and is already used by
--   many working spellclick vehicles in this DB with cast_flags=1
--   (player casts, aura lands on the cart -> player boards).
--   This mirrors the official npc_delivery_cart behaviour of
--   casting ForceVehicleRide (46598) on the player.
-- ============================================================

UPDATE `npc_spellclick_spells`
SET `spell_id` = 46598, `cast_flags` = 1
WHERE `npc_entry` IN (57710, 57741);


-- ############################################################
-- ## SECTION FROM: 2026_10_02_03_world_cart_remove_disable_move.sql
-- ############################################################

-- ============================================================
-- Fix (follow-up 3): cart boards the player but never moves
--
-- Root cause: static prop carts carry UNIT_FLAG_DISABLE_MOVE
-- (creature_template.unit_flags = 0x4200; bit 0x4000).
-- MotionMaster refuses to start any movement for owners with
-- that flag (MotionMaster.cpp "HasUnitFlag(UNIT_FLAG_DISABLE_MOVE)"
-- guards), so the WP_START ride path silently did nothing.
--
-- Fix: on PassengerBoarded, clear 0x4000 with SMART_ACTION_REMOVE_
-- UNIT_FLAG (action 19) as a linked action (link=1 row paired to
-- the event row). The flag comes back automatically when the
-- creature respawns from its template.
-- ============================================================

-- 57710 (Singing Pools cart, quest 29680): linked flag-clear on the
-- PassengerBoarded event (id 2, link 0 stays the event; link 1 runs
-- alongside it).
DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = 57710 AND `id` = 2 AND `link` = 1;

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (57710, 0, 2, 1, 0, 0, 100, 0, 0, 0, 0, 0, 0,
     19, 16384, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - On Passenger Boarded - Remove Disable Move Flag');

-- 57741 (Wreck cart, quest 29800): same treatment on its id 0 event.
DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = 57741 AND `id` = 0 AND `link` = 1;

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (57741, 0, 0, 1, 0, 0, 100, 0, 0, 0, 0, 0, 0,
     19, 16384, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - On Passenger Boarded - Remove Disable Move Flag');


-- ############################################################
-- ## SECTION FROM: 2026_10_02_04_world_smartai_waypoints_ride.sql
-- ############################################################

-- ============================================================
-- Fix (follow-up 4): cart boards, flag cleared, but still no ride
--
-- Root causes (two more):
--   1. SmartAI's WP_START escort movement reads the `waypoints`
--      table (SmartWaypointMgr, loaded at startup), NOT
--      `waypoint_data`. Our path ids 5720800/5774000 did not
--      exist there, so SmartAI::StartPath silently returned.
--   2. SMART_EVENT_WAYPOINT_REACHED is raised with var1 = 0
--      (SmartAI::MovepointReached passes only the point id),
--      so event_param2 = <pathId> could never match. Must be 0
--      (= any path). WAYPOINT_ENDED (58) does pass the path id,
--      so it was fine.
--
-- NOTE: there is no `.reload` command for the `waypoints` table
-- (only loaded at worldserver startup) -> RESTART REQUIRED.
-- ============================================================

-- 1) Escort path for SmartAI WP_START: Singing Pools cart -> Dai-Lo Farmstead
DELETE FROM `waypoints` WHERE `entry` = 5720800;
INSERT INTO `waypoints`
    (`entry`, `pointid`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `point_comment`)
VALUES
    (5720800,  1, 940.00, 2856.00,  80.20, NULL, 0, 'Delivery Cart ride - head west along the pools'),
    (5720800,  2, 896.00, 2856.00,  80.20, NULL, 0, NULL),
    (5720800,  3, 852.00, 2856.00,  80.20, NULL, 0, NULL),
    (5720800,  4, 816.00, 2832.00,  86.30, NULL, 0, NULL),
    (5720800,  5, 776.00, 2828.00,  82.90, NULL, 0, NULL),
    (5720800,  6, 756.00, 2864.00,  75.50, NULL, 0, NULL),
    (5720800,  7, 740.00, 2904.00,  75.10, NULL, 0, NULL),
    (5720800,  8, 704.00, 2928.00,  75.90, NULL, 0, NULL),
    (5720800,  9, 680.00, 2964.00,  75.40, NULL, 0, NULL),
    (5720800, 10, 684.00, 3004.00,  79.50, NULL, 0, 'bridge over the river gorge (deck height)'),
    (5720800, 11, 664.00, 3036.00,  79.50, NULL, 0, NULL),
    (5720800, 12, 632.00, 3064.00,  80.40, NULL, 0, NULL),
    (5720800, 13, 620.00, 3104.00,  87.80, NULL, 0, NULL),
    (5720800, 14, 628.00, 3140.00,  88.30, NULL, 0, 'Dai-Lo Farmstead (next to Ji) - eject point');

-- 2) Escort path: Wreck cart -> Temple of Five Dawns
DELETE FROM `waypoints` WHERE `entry` = 5774000;
INSERT INTO `waypoints`
    (`entry`, `pointid`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `point_comment`)
VALUES
    (5774000,  1, 312.00, 3872.00,  78.80, NULL, 0, 'Delivery Cart ride - leave the wreck'),
    (5774000,  2, 356.00, 3876.00,  78.60, NULL, 0, NULL),
    (5774000,  3, 392.00, 3852.00,  78.40, NULL, 0, NULL),
    (5774000,  4, 436.00, 3840.00,  78.60, NULL, 0, NULL),
    (5774000,  5, 472.00, 3820.00,  76.80, NULL, 0, NULL),
    (5774000,  6, 504.00, 3796.00,  79.10, NULL, 0, NULL),
    (5774000,  7, 524.00, 3756.00,  79.60, NULL, 0, NULL),
    (5774000,  8, 560.00, 3724.00,  83.40, NULL, 0, NULL),
    (5774000,  9, 592.00, 3696.00, 101.20, NULL, 0, 'climb towards the temple terrace'),
    (5774000, 10, 604.00, 3664.00, 115.60, NULL, 0, NULL),
    (5774000, 11, 616.00, 3636.00, 129.80, NULL, 0, NULL),
    (5774000, 12, 656.00, 3612.00, 146.30, NULL, 0, NULL),
    (5774000, 13, 696.00, 3612.00, 144.00, NULL, 0, NULL),
    (5774000, 14, 736.00, 3632.00, 141.10, NULL, 0, NULL),
    (5774000, 15, 772.00, 3660.00, 141.30, NULL, 0, NULL),
    (5774000, 16, 784.00, 3648.00, 158.30, NULL, 0, NULL),
    (5774000, 17, 824.00, 3632.00, 163.80, NULL, 0, 'Temple of Five Dawns terrace - eject point');

-- 3) The old waypoint_data rows are unused by SmartAI escort movement
--    (spawn movementType = 0); drop them to avoid future confusion.
DELETE FROM `waypoint_data` WHERE `id` IN (5720800, 5774000);

-- 4) WAYPOINT_REACHED fires with pathId = 0 (any path); fix the matcher.
UPDATE `smart_scripts`
SET `event_param2` = 0
WHERE `source_type` = 0 AND `entryorguid` IN (57710, 57741) AND `event_type` = 40;


-- ############################################################
-- ## SECTION FROM: 2026_10_02_05_world_yak_lead_path.sql
-- ############################################################

-- ============================================================
-- Fix (follow-up 5): the yak never moves / must lead in FRONT
--
-- Root causes:
--   1. creature_template 57709 (Nourished Yak) has AIName = ''
--      -> the SAI loader skips all its scripts entirely.
--   2. SMART_ACTION_FOLLOW in the cart's action list acts on the
--      script OWNER (the cart), not the yak - the yak received
--      no movement instruction at all.
--   3. SMART_EVENT_DATA_SET matches BOTH id and value exactly;
--      the previous "go home" signal (SetData(1,1)) could never
--      match event_param2 = 0.
--
-- Design: on boarding, the cart signals DATA 2/1 -> the yak runs
-- its OWN lead path (same route, offset 4.5 yd ahead, terrain
-- sampled), staying in front pulling the cart. Rope spell 108877
-- stays on the cart as the visual link. When the cart's path
-- ends it signals DATA 1/1 -> the yak walks home.
-- Yak speed_run already matches the cart (1.14286).
-- NOTE: requires worldserver restart (waypoints table anyway).
-- ============================================================

-- 1) Let the yak run SmartAI at all
UPDATE `creature_template`
SET `AIName` = 'SmartAI'
WHERE `entry` = 57709;

-- 2) Yak lead path (cart route shifted 4.5 yd forward, terrain z)
DELETE FROM `waypoints` WHERE `entry` = 5770900;
INSERT INTO `waypoints`
    (`entry`, `pointid`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `point_comment`)
VALUES
    (5770900,  1, 935.50, 2856.00,  79.93, NULL, 0, 'Nourished Yak lead path (4.5 yd ahead of cart)'),
    (5770900,  2, 891.50, 2856.00,  79.93, NULL, 0, NULL),
    (5770900,  3, 847.69, 2854.71,  79.93, NULL, 0, NULL),
    (5770900,  4, 811.78, 2830.44,  85.78, NULL, 0, NULL),
    (5770900,  5, 772.03, 2830.12,  81.40, NULL, 0, NULL),
    (5770900,  6, 754.07, 2868.07,  75.21, NULL, 0, NULL),
    (5770900,  7, 737.16, 2907.49,  74.80, NULL, 0, NULL),
    (5770900,  8, 700.82, 2931.18,  75.64, NULL, 0, NULL),
    (5770900,  9, 678.85, 2968.35,  75.08, NULL, 0, NULL),
    (5770900, 10, 683.02, 3008.39,  78.00, NULL, 0, 'bridge deck'),
    (5770900, 11, 661.05, 3039.40,  78.07, NULL, 0, NULL),
    (5770900, 12, 629.56, 3067.78,  80.62, NULL, 0, NULL),
    (5770900, 13, 619.76, 3108.49,  87.61, NULL, 0, NULL),
    (5770900, 14, 628.98, 3144.39,  88.03, NULL, 0, 'Dai-Lo Farmstead');

-- 3) Cart action list: drop the wrong-direction FOLLOW, add the
--    yak start signal right before the cart starts moving.
DELETE FROM `smart_scripts`
WHERE `source_type` = 9 AND `entryorguid` = 5771001;

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (5771001, 9, 0, 0, 0, 0, 100, 0, 500, 500, 0, 0, 0,
     11, 108877, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - Cast Ox Cart Rope Left (visual link)'),
    (5771001, 9, 1, 0, 0, 0, 100, 0, 1800, 1800, 0, 0, 0,
     45, 2, 1, 0, 0, 0, 0, 19, 57709, 15, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - Signal Yak (DATA 2/1) - Start Lead Path'),
    (5771001, 9, 2, 0, 0, 0, 100, 0, 1900, 1900, 0, 0, 0,
     53, 1, 5720800, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - Start Ride Path (run, no repeat)');

-- 4) Yak SAI: start lead path on DATA 2/1, go home on DATA 1/1.
--    (SetData(field, data) -> event matches id=field, value=data exactly.)
DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = -562165;

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (-562165, 0, 0, 0, 38, 0, 100, 0, 2, 1, 0, 0, 0,
     53, 1, 5770900, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Nourished Yak - Cart Signal DATA 2/1 - Start Lead Path (run)'),
    (-562165, 0, 1, 0, 38, 0, 100, 0, 1, 1, 0, 0, 0,
     69, 1, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 979.37, 2860.29, 88.38, 0,
     'Nourished Yak - Cart Signal DATA 1/1 - Move Home');


-- ############################################################
-- ## SECTION FROM: 2026_10_02_06_world_cart_follow_yak.sql
-- ############################################################

-- ============================================================
-- Fix #6: Quest 29680 Delivery Cart - speed sync via FOLLOW
-- Problem: cart (WP_START own path) and yak (own lead path) move at
--          different effective speeds; cart outruns the yak.
-- Solution: cart no longer runs its own path. It FOLLOWS the lead yak
--          (SMART_ACTION_FOLLOW, dist 5yd, angle 0 = directly behind).
--          Eject + despawn are now triggered by the YAK reaching the
--          final lead waypoint (event 40, point 14), not by the cart.
-- Notes:
--  * Applies to 29680 chain only (57710 + yak 57709 guid 562165).
--  * 29800 (57741) keeps its own path - no yak spawn exists for it.
--  * Path 5720800 in `waypoints` is now unused by this chain (kept as
--    fallback).
-- Requires: .reload smart_scripts (or worldserver restart)
-- ============================================================

-- 1) Cart ride actionlist: replace WP_START with FOLLOW the yak
UPDATE `smart_scripts` SET
  `action_type` = 29,           -- SMART_ACTION_FOLLOW
  `action_param1` = 5,          -- distance (yd)
  `action_param2` = 0,          -- angle (0 = directly behind target)
  `target_type` = 19,           -- closest creature
  `target_param1` = 57709,      -- ...of entry Nourished Yak
  `target_param2` = 15,         -- search radius
  `comment` = 'Delivery Cart - Follow Lead Yak (speed sync)'
WHERE `source_type` = 9 AND `entryorguid` = 5771001 AND `id` = 2;

-- 2) Cart: remove waypoint-based eject / go-home / despawn handlers
DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = 57710 AND `id` IN (3,4,5);

-- 3) Cart: on DATA 3/1 from yak -> eject passengers, despawn after 1s
DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = 57710 AND `id` IN (6,7);
INSERT INTO `smart_scripts`
 (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
  `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
  `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
  `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
 (57710,0,6,0,38,0,100,0, 3,1,0,0,0, 11,50630,0,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Delivery Cart - Yak Reached Farmstead (DATA 3/1) - Eject Passengers'),
 (57710,0,7,6,0,0,100,0, 0,0,0,0,0, 41,1000,0,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Delivery Cart - Eject Link - Force Despawn (1s)');

-- 4) Yak: on reaching final lead point (14) -> signal cart to eject+despawn,
--    then walk home (replace old DATA 1/1 handler which never fires now)
DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = -562165 AND `id` = 1;
INSERT INTO `smart_scripts`
 (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
  `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
  `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
  `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
 (-562165,0,1,0,40,0,100,0, 14,0,0,0,0, 45,3,1,0,0,0,0, 19,57710,15,0,0,0,0,0,0,'Nourished Yak - Reached Farmstead Point 14 - Signal Cart DATA 3/1 (eject+despawn)'),
 (-562165,0,1,1,0,0,100,0, 0,0,0,0,0, 69,1,0,0,0,0,0, 8,0,0,0,0,979.37,2860.29,88.38,0,'Nourished Yak - Reached Farmstead Link - Move Home');


-- ############################################################
-- ## SECTION FROM: 2026_10_02_07_world_cart_finale_links.sql
-- ############################################################

-- ============================================================
-- Fix #7: Quest 29680 finale (eject + despawn + yak return)
-- Root cause: previous link chains were malformed. Core semantics
-- (SmartScript::ProcessAction / FindLinkedEvent):
--   * an event row fires its linked action only if its `link` column
--     is non-zero AND a row exists whose `id` column == that value
--     and whose event_type = 0 (SMART_EVENT_LINK).
--   * the old rows had event rows with link=0 and link rows under
--     mismatched ids -> none of the finale actions ever ran.
-- New design (fewer hops, redundant triggers):
--   Yak (leader, escort path 5770900):
--     event 40 point 14        -> cast 50630 (Eject Passengers) on nearest
--                                 57710 (within 15yd), link -> move home
--     event 58 path 5770900    -> same (backup trigger at path end)
--   Cart (follower):
--     event 31 spellhit 50630  -> cast 50630 on self (redundancy),
--                                 link -> FORCE_DESPAWN after 1s
-- Side fix: creature_template 57741 (29800 cart) had empty AIName, its
--   whole SAI was skipped by the loader (see DBErrors.log). Set SmartAI.
--   NOTE: requires worldserver restart (template change).
-- Reload: .reload smart_scripts
-- ============================================================

-- ---- Yak (guid 562165) - rewrite finale ----
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = -562165;
INSERT INTO `smart_scripts`
 (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
  `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
  `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
  `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
 (-562165,0,0,0,38,0,100,0, 2,1,0,0,0, 53,1,5770900,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Nourished Yak - Cart Signal DATA 2/1 - Start Lead Path (run)'),
 (-562165,0,1,11,40,0,100,0, 14,0,0,0,0, 11,50630,0,0,0,0,0, 19,57710,15,0,0,0,0,0,0,'Nourished Yak - Reached Lead Point 14 - Cast Eject Passengers on Cart'),
 (-562165,0,11,0,0,0,100,0, 0,0,0,0,0, 69,1,0,0,0,0,0, 8,0,0,0,0,979.37,2860.29,88.38,0,'Nourished Yak - Link - Move Home'),
 (-562165,0,12,11,58,0,100,0, 0,5770900,0,0,0, 11,50630,0,0,0,0,0, 19,57710,15,0,0,0,0,0,0,'Nourished Yak - Lead Path Ended (backup) - Cast Eject Passengers on Cart');

-- ---- Cart 57710 - replace broken DATA chain with spellhit reaction ----
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = 57710 AND `id` IN (6,7);
INSERT INTO `smart_scripts`
 (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
  `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
  `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
  `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
 (57710,0,10,11,31,0,100,0, 50630,0,0,0,0, 11,50630,0,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Delivery Cart - On Eject Spellhit - Cast Eject Passengers (self, redundancy)'),
 (57710,0,11,0,0,0,100,0, 0,0,0,0,0, 41,1000,0,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Delivery Cart - Link - Force Despawn (1s)');

-- ---- Cart 57710 - repair the boarding flag link (was pointing nowhere) ----
UPDATE `smart_scripts` SET `link` = 3
WHERE `source_type` = 0 AND `entryorguid` = 57710 AND `id` = 2 AND `event_type` = 27;
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = 57710 AND `id` = 2 AND `link` <> 0 AND `event_type` = 0;
INSERT INTO `smart_scripts`
 (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
  `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
  `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
  `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
 (57710,0,3,0,0,0,100,0, 0,0,0,0,0, 19,16384,0,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Delivery Cart - Link - Remove Disable Move Flag');

-- ---- Side fix: 57741 AIName (restart required) ----
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 57741;


-- ############################################################
-- ## SECTION FROM: 2026_10_02_08_world_quest_29774_not_in_the_face.sql
-- ############################################################

-- ============================================================
-- Fix: Quest 29774 (别泼脸！/ Not In the Face!) - objective
--      "唤醒无垢" (Wake Wugou) stuck at 0/1.
--
-- Official chain (verified against DB + core source):
--   accept quest at Ji Firepaw 55477
--     -> Ji SAI event 19 summons Wugou 57760 (invisible quest-credit
--        carrier, aura 42386) and Shu 55556 at the waterfall pool
--     -> gossip select (menu 13140) awards credit 55548 (obj0 done)
--        and summons Shu 55558, then 55556 despawns
--     -> Shu 55558 runs escort path 55558, pauses at point 5, sprays
--        spell 118027 at Wugou 57760
--     -> spellhit removes 42386 and awards credit 55547 (obj1).
--
-- Issues fixed here:
--   1. Ji summoned Wugou at POSITION (0,0,0), relying on the summoned
--      creature's own JUST_SUMMONED teleport to reach the farmstead.
--      Summon directly at the real farmstead coords instead.
--   2. Shu 55558 WAYPOINT_REACHED matcher carries pathId (55558) in
--      event_param2 - same fork trap as the delivery-cart fix
--      (2026_10_02_04: the event fires with point id only) - set 0.
--   3. Face/splash target radius was 10yd while point 5 -> Wugou is
--      9.73yd (no margin); widen to 15yd so the spray cannot miss.
--
-- NOTE: temp summons do NOT survive a worldserver restart. After
--   applying, ABANDON quest 29774 and RE-ACCEPT it from Ji Firepaw
--   so both NPCs are re-summoned, then talk to Shu at the waterfall.
-- Reload: .reload smart_scripts
-- ============================================================

-- 1) Ji Firepaw: summon Wugou 57760 directly at the farmstead spot
UPDATE `smart_scripts` SET
  `target_x` = 631.479,
  `target_y` = 3140.7,
  `target_z` = 87.8357
WHERE `source_type` = 0 AND `entryorguid` = 55477 AND `id` = 1
  AND `event_type` = 19 AND `action_type` = 12 AND `action_param1` = 57760;

-- 2) Shu 55558: drop pathId from the WAYPOINT_REACHED matcher
-- (historical: these rows were later deleted and rewritten by the
--  event_type=61 fix below - kept for chronological fidelity)
UPDATE `smart_scripts` SET `event_param2` = 0
WHERE `source_type` = 0 AND `entryorguid` = 55558 AND `id` = 1
  AND `event_type` = 40;

-- 3) Shu 55558: widen face + splash target search radius 10 -> 15 yd
UPDATE `smart_scripts` SET `target_param2` = 15
WHERE `source_type` = 0 AND `entryorguid` = 55558 AND `id` IN (2, 5)
  AND `target_type` = 19 AND `target_param1` = 57760 AND `target_param2` = 10;


-- ############################################################
-- ## SECTION FROM: 2026_10_02_10_world_link_rows_event_type_61.sql
-- ############################################################

-- ============================================================
-- Fix: SAI link rows must use event_type = 61 (SMART_EVENT_LINK).
--
-- This fork: SmartScript::ProcessAction requires the linked row to
-- have GetEventType() == SMART_EVENT_LINK, and SmartScriptMgr.h
-- defines SMART_EVENT_LINK = 61. Rows written with event_type = 0
-- (UPDATE_IC) are never executed as links - DBErrors.log showed:
--   "Entry 55558 ... Link Event 11/12 not found or invalid, skipped."
-- They are ALSO registered as in-combat timer events (unwanted).
--
-- Consequence for quest 29774: Shu 55558 ran to the splash spot and
-- faced Wugou, but the whole splash chain (118034 -> 118027 wake
-- splash -> laugh -> despawn + 30s fallback) never executed because
-- every link hop was broken. Wugou stayed asleep forever.
-- Same defect existed in the delivery-cart finale (fix 07): yak link
-- row (walk home) and cart link rows (clear flag / force despawn).
--
-- 1) Shu 55558: rewrite with event_type=61 link rows (same flow).
-- 2) Yak -562165 id 11 (walk home): 0 -> 61.
-- 3) Cart 57710 id 3 (clear DisableMove), id 11 (despawn): 0 -> 61.
--
-- Reload: .reload smart_scripts, then ABANDON + RE-ACCEPT 29774.
-- ============================================================

-- 1) Shu 55558 rewrite
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = 55558;

INSERT INTO `smart_scripts`
 (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
  `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
  `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
  `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
 -- summoned -> arm timer 1 (500ms)
 (55558,0,0,0,54,0,100,0, 0,0,0,0,0,
  67,1,500,500,0,0,0, 1,0,0,0,0,0,0,0,0,'Shu - On Summoned - Timed Event 1 (500ms)'),
 -- timer 1 -> run to splash spot in front of Wugou
 (55558,0,10,0,59,0,100,0, 1,0,0,0,0,
  69,1,0,0,0,0,0, 8,0,0,0,0,621.747,3140.77,87.837,0,'Shu - Timed Event 1 - Move To Splash Spot (Point 1)'),
 -- arrival -> face Wugou, then link chain
 (55558,0,11,12,34,0,100,0, 8,1,0,0,0,
  66,0,0,0,0,0,0, 19,57760,15,0,0,0,0,0,0,'Shu - Arrived At Splash Spot - Face Wugou'),
 (55558,0,12,13,61,0,100,0, 0,0,0,0,0,
  11,118034,0,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Shu - Link - Cast Water Splash (visual)'),
 (55558,0,13,14,61,0,100,0, 0,0,0,0,0,
  67,2,2000,2000,0,0,0, 1,0,0,0,0,0,0,0,0,'Shu - Link - Timed Event 2 (wake splash, 2s)'),
 (55558,0,14,0,61,0,100,0, 0,0,0,0,0,
  67,3,30000,30000,0,0,0, 1,0,0,0,0,0,0,0,0,'Shu - Link - Timed Event 3 (fallback splash, 30s)'),
 -- timer 2 -> wake splash at Wugou, then laugh + despawn
 (55558,0,15,16,59,0,100,0, 2,0,0,0,0,
  11,118027,0,0,0,0,0, 19,57760,15,0,0,0,0,0,0,'Shu - Timed Event 2 - Cast Shu''s Water Splash At Wugou'),
 (55558,0,16,17,61,0,100,0, 0,0,0,0,0,
  11,118035,0,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Shu - Link - Cast Water Spirit Laugh'),
 (55558,0,17,0,61,0,100,0, 0,0,0,0,0,
  41,3000,0,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Shu - Link - Despawn (3s)'),
 -- fallback splash if arrival path was missed
 (55558,0,18,0,59,0,100,0, 3,0,0,0,0,
  11,118027,0,0,0,0,0, 19,57760,15,0,0,0,0,0,0,'Shu - Timed Event 3 (fallback) - Cast Water Splash At Wugou'),
 -- flavor: laugh when Wugou signals DATA 0/1
 (55558,0,6,0,38,0,100,0, 0,1,0,0,0,
  11,118035,0,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Shu - On Data Set 0 1 - Cast Water Spirit Laugh');

-- 2) Yak link row: walk home after ejecting passengers
UPDATE `smart_scripts`
SET `event_type` = 61
WHERE `entryorguid` = -562165 AND `source_type` = 0 AND `id` = 11 AND `event_type` = 0;

-- 3) Cart link rows: clear DisableMove on boarding + despawn after eject
UPDATE `smart_scripts`
SET `event_type` = 61
WHERE `entryorguid` = 57710 AND `source_type` = 0 AND `id` IN (3, 11) AND `event_type` = 0;


-- ############################################################
-- ## SECTION FROM: 2026_10_02_11_world_quest_29775_farmstead_cart_ride.sql
-- ############################################################

-- ============================================================
-- Fix: Quest 29775 (The Spirit and Body of Shen-zin Su) - the
-- farmstead Delivery Cart 59497 cannot be ridden at all.
--
-- Root cause: official design is two-stage - clicking the static
-- cart 59497 casts spell 114453 (effect 28 = SPELL_EFFECT_SUMMON_
-- VEHICLE) which summons rideable cart 59496, driven by C++
-- npc_delivery_cart. This fork NEVER implemented effect 28 (no
-- SPELL_EFFECT_SUMMON_VEHICLE anywhere in Spells/), the follow yak
-- 59498 has no spawn/AI/path, and path 5949600 does not exist.
-- Result: clicking the cart does nothing; the player is left behind.
--
-- Fix: convert 59497 to the proven direct-ride pattern already used
-- for the bridge cart 57710:
--   * VehicleId 1944 + spellclick 46598 (Control Vehicle aura 236)
--   * On boarding: quest credit (KilledMonsterCredit 59497),
--     Disable-Move flag cleared, ride actionlist (rope visual ->
--     signal yak DATA 2/1 -> cart FOLLOWS yak 59499, dist 5)
--   * Yak 59499 (guid 563607) becomes SmartAI and runs its own lead
--     path 5949900 (15 pts, farmstead -> Temple of Five Dawns base,
--     .map-sampled, each point 4.5 yd ahead of the cart line)
--   * At lead point 15 (temple base, 824,3632): yak casts 50630 on
--     the cart -> passengers ejected; cart Force Despawn 1s;
--     yak MOVE_TO_POS home (spawn point). Backup trigger: event 58.
--   * Objective 276326 text: 乘坐牛车前往五晨寺 (zhCN)
--
-- NOTE: requires WORLDSERVER RESTART (creature_template VehicleId/
-- AIName + npc_spellclick_spells + waypoints table have no reload).
-- ============================================================

-- 1) Cart 59497 directly rideable
UPDATE `creature_template` SET `VehicleId` = 1944 WHERE `entry` = 59497;
UPDATE `npc_spellclick_spells` SET `spell_id` = 46598, `cast_flags` = 1 WHERE `npc_entry` = 59497;

-- 2) Yak 59499 gets a working AI
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 59499;

-- 3) Cart 59497 SAI (official id0 respawn rope + id1 rope spellhit kept)
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = 59497 AND `id` >= 2;

INSERT INTO `smart_scripts`
 (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
  `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
  `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
  `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
 -- boarded -> quest credit 29775, then chain
 (59497,0,2,3,27,0,100,0, 0,0,0,0,0,
  33,59497,0,0,0,0,0, 18,20,0,0,0,0,0,0,0,'Delivery Cart (Farm) - On Passenger Boarded - Quest Credit'),
 (59497,0,3,4,61,0,100,0, 0,0,0,0,0,
  19,16384,0,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Delivery Cart (Farm) - Link - Remove Disable Move Flag'),
 (59497,0,4,0,61,0,100,0, 0,0,0,0,0,
  80,5949701,0,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Delivery Cart (Farm) - Link - Start Ride Script'),
 -- ejected at temple -> self-eject redundancy + despawn
 (59497,0,10,11,31,0,100,0, 50630,0,0,0,0,
  11,50630,0,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Delivery Cart (Farm) - On Eject Spellhit - Cast Eject Passengers (self)'),
 (59497,0,11,0,61,0,100,0, 0,0,0,0,0,
  41,1000,0,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Delivery Cart (Farm) - Link - Force Despawn (1s)');

-- 4) Ride actionlist (mirror of proven 5771001)
DELETE FROM `smart_scripts` WHERE `source_type` = 9 AND `entryorguid` = 5949701;

INSERT INTO `smart_scripts`
 (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
  `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
  `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
  `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
 (5949701,9,0,0,0,0,100,0, 500,0,0,0,0,
  11,108877,0,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Delivery Cart (Farm) - Cast Ox Cart Rope Left (visual)'),
 (5949701,9,1,0,0,0,100,0, 1800,0,0,0,0,
  45,2,1,0,0,0,0, 19,59499,15,0,0,0,0,0,0,'Delivery Cart (Farm) - Signal Yak (DATA 2/1) - Start Lead Path'),
 (5949701,9,2,0,0,0,100,0, 1900,0,0,0,0,
  29,5,0,0,0,0,0, 19,59499,15,0,0,0,0,0,0,'Delivery Cart (Farm) - Follow Lead Yak (speed sync)');

-- 5) Yak 59499 SAI (guid 563607, mirror of proven -562165)
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = -563607;

INSERT INTO `smart_scripts`
 (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
  `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
  `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
  `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
 (-563607,0,0,0,38,0,100,0, 2,1,0,0,0,
  53,1,5949900,0,0,0,0, 1,0,0,0,0,0,0,0,0,'Nourished Yak (Farm) - Cart Signal DATA 2/1 - Start Lead Path (run)'),
 (-563607,0,1,11,40,0,100,0, 15,0,0,0,0,
  11,50630,0,0,0,0,0, 19,59497,15,0,0,0,0,0,0,'Nourished Yak (Farm) - Reached Lead Point 15 - Cast Eject Passengers on Cart'),
 (-563607,0,11,0,61,0,100,0, 0,0,0,0,0,
  69,1,0,0,0,0,0, 8,0,0,0,0,587.615,3161.92,89.3098,0,'Nourished Yak (Farm) - Link - Move Home'),
 (-563607,0,12,11,58,0,100,0, 0,5949900,0,0,0,
  11,50630,0,0,0,0,0, 19,59497,15,0,0,0,0,0,0,'Nourished Yak (Farm) - Lead Path Ended (backup) - Cast Eject Passengers on Cart');

-- 6) Yak lead path 5949900 (farmstead -> Temple of Five Dawns base)
DELETE FROM `waypoints` WHERE `entry` = 5949900;

INSERT INTO `waypoints` (`entry`,`pointid`,`position_x`,`position_y`,`position_z`,`delay`,`point_comment`) VALUES
 (5949900, 1, 589.18, 3168.34,  88.89, 0, 'Farm cart lead - yak +4.5yd'),
 (5949900, 2, 597.99, 3212.02,  87.22, 0, 'Farm cart lead - yak +4.5yd'),
 (5949900, 3, 588.41, 3236.48,  70.19, 0, 'Farm cart lead - yak +4.5yd'),
 (5949900, 4, 592.80, 3280.43,  69.42, 0, 'Farm cart lead - yak +4.5yd'),
 (5949900, 5, 602.01, 3324.02,  75.59, 0, 'Farm cart lead - yak +4.5yd'),
 (5949900, 6, 622.76, 3363.55,  90.13, 0, 'Farm cart lead - yak +4.5yd'),
 (5949900, 7, 650.50, 3399.74,  97.58, 0, 'Farm cart lead - yak +4.5yd'),
 (5949900, 8, 674.99, 3435.36, 108.37, 0, 'Farm cart lead - yak +4.5yd'),
 (5949900, 9, 707.36, 3470.99, 118.62, 0, 'Farm cart lead - yak +4.5yd'),
 (5949900,10, 742.76, 3503.55, 136.81, 0, 'Farm cart lead - yak +4.5yd'),
 (5949900,11, 772.02, 3538.01, 140.46, 0, 'Farm cart lead - yak +4.5yd'),
 (5949900,12, 793.29, 3552.31, 157.36, 0, 'Farm cart lead - yak +4.5yd'),
 (5949900,13, 804.80, 3592.43, 159.62, 0, 'Farm cart lead - yak +4.5yd'),
 (5949900,14, 816.50, 3632.00, 159.72, 0, 'Farm cart lead - yak +4.5yd'),
 (5949900,15, 828.50, 3632.00, 170.07, 0, 'Farm cart lead - temple base (eject point)');

-- 7) Objective text
UPDATE `quest_objective` SET `description` = '乘坐牛车前往五晨寺' WHERE `questId` = 29775 AND `objectId` = 59497;
INSERT INTO `quest_objectives_locale` (`ID`,`locale`,`QuestId`,`StorageIndex`,`Description`,`VerifiedBuild`)
VALUES (29775,'zhCN',29775,0,'乘坐牛车前往五晨寺',18414);


-- ############################################################
-- ## SECTION FROM: 2026_10_02_12_world_farm_cart_timed_list_param.sql
-- ############################################################

-- ============================================================
-- Fix 12: Quest 29775 farmstead cart - timed action list never loaded
--
-- Root cause: smart_scripts rows in timed action list 5949701
-- (source_type=9) must have event_param1 AND event_param2 set
-- (min/max delay, equal values = fixed delay). They were written
-- with event_param2=0, so SmartAIMgr rejected all 3 rows at load:
--   "Entry 5949701 SourceType 9 Event N Action X uses min/max
--    params wrong (P1/0), skipped."
-- Result: rope visual / SET_DATA(2,1) to yak / FOLLOW chain never
-- established -> neither yak 59499 nor cart 59497 ever moved.
--
-- Fix: mirror the working bridge list 5771001 (param2 = param1).
-- Hot-reloadable: .reload smart_scripts is enough.
-- ============================================================

UPDATE `smart_scripts`
SET `event_param2` = `event_param1`
WHERE `entryorguid` = 5949701
  AND `source_type` = 9
  AND `event_param2` = 0
  AND `event_param1` IN (500, 1800, 1900);



-- ############################################################
-- ## SECTION 13: Yak lead path 5770900 -> 18 pts recorded in-game
-- ## (CoordRecorder plugin, 2026-10-02) + arrival behavior
-- ############################################################

-- ① Replace the 14 estimated points with 18 measured points
--    (bridge head -> Dai-Lo Farmstead, spawn 979.373/2860.29/88.378)
DELETE FROM `waypoints` WHERE `entry` = 5770900;
INSERT INTO `waypoints`
    (`entry`, `pointid`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `point_comment`)
VALUES
    (5770900,  1, 981.41, 2850.65, 87.77, NULL, 0, 'bridge head (recorded in-game)'),
    (5770900,  2, 945.02, 2832.88, 86.84, NULL, 0, NULL),
    (5770900,  3, 918.10, 2824.97, 86.88, NULL, 0, NULL),
    (5770900,  4, 897.29, 2811.17, 86.81, NULL, 0, NULL),
    (5770900,  5, 858.52, 2802.30, 82.23, NULL, 0, NULL),
    (5770900,  6, 804.21, 2783.38, 76.50, NULL, 0, NULL),
    (5770900,  7, 792.37, 2788.14, 75.49, NULL, 0, NULL),
    (5770900,  8, 747.29, 2831.72, 75.44, NULL, 0, NULL),
    (5770900,  9, 745.04, 2847.36, 75.55, NULL, 0, NULL),
    (5770900, 10, 756.55, 2876.57, 74.84, NULL, 0, NULL),
    (5770900, 11, 746.66, 2900.25, 74.91, NULL, 0, NULL),
    (5770900, 12, 688.20, 2954.14, 74.55, NULL, 0, NULL),
    (5770900, 13, 667.16, 2981.86, 74.61, NULL, 0, NULL),
    (5770900, 14, 652.27, 3001.48, 74.59, NULL, 0, NULL),
    (5770900, 15, 626.91, 3018.33, 74.95, NULL, 0, NULL),
    (5770900, 16, 613.63, 3044.37, 77.01, NULL, 0, NULL),
    (5770900, 17, 614.30, 3091.10, 85.76, NULL, 0, NULL),
    (5770900, 18, 624.28, 3136.91, 87.75, NULL, 0, 'Dai-Lo Farmstead (arrival point)');

-- ② Arrival trigger: MOVEMENTINFORM point 14 -> 18
UPDATE `smart_scripts`
SET `event_param1` = 18
WHERE `source_type` = 0
  AND `entryorguid` = -562165
  AND `id` = 1
  AND `event_type` = 40;

-- ③ Arrival behavior: yak no longer walks home; BOTH yak and cart
--    Force Despawn 5s after eject and respawn at spawn coordinates
--    (respawn interval = creature.spawntimesecs)
UPDATE `smart_scripts`
SET `action_type` = 41, `action_param1` = 5000,
    `target_type` = 1, `target_param1` = 0
WHERE `source_type` = 0
  AND `entryorguid` = -562165
  AND `id` = 11
  AND `event_type` = 61;

UPDATE `smart_scripts`
SET `action_param1` = 5000
WHERE `source_type` = 0
  AND `entryorguid` = 57710
  AND `id` = 11
  AND `action_type` = 41;


-- ############################################################
-- ## SECTION 14: Cart follow angle -> directly behind the yak
-- ############################################################
-- ChaseAngle semantics: RelativeAngle 0 = IN FRONT of the target,
-- M_PI (180 deg) = directly behind (Position.h: GetRelativeAngle =
-- GetAngle(pos) - orientation). Old value 0 made the cart aim at the
-- yak's FRONT arc (+-45 deg tolerance), so it trailed behind-right
-- (pathfinding blocks it from passing through the yak's body).
-- 180 = rear arc +-45 deg, target point = exact rear.

UPDATE `smart_scripts`
SET `action_param2` = 180
WHERE `source_type` = 9
  AND `entryorguid` = 5771001
  AND `id` = 2
  AND `action_type` = 29;


-- ############################################################
-- ## SECTION 15: Unified respawn for yak + delivery cart
-- ############################################################
-- Both despawn 5s after arrival (yak: own link id11; cart: spellhit
-- 50630 -> self-cast eject -> link id11 ForceDespawn 5000ms).
-- Respawn delay = creature.spawntimesecs (this fork's FORCE_DESPAWN
-- has no forceRespawnTime param). Old values 180s/300s felt like
-- "never respawns"; unified to 60s at the spawn coordinates
-- (yak 979.37/2860.29, cart 979.07/2863.87 = bridge head).

UPDATE `creature`
SET `spawntimesecs` = 60
WHERE `guid` IN (562165, 562546) AND `id` IN (57709, 57710);


-- ############################################################
-- ## SECTION 16: Cart 57710 spawn point -> measured in-game
-- ############################################################
-- Measured with the CoordRecorder plugin (2026-10-02).
-- Arrival behavior is already final (see SECTION 13/15): on reaching
-- lead point 18 the yak casts 50630 on the cart, passengers are
-- ejected, and BOTH cart and yak Force Despawn after 5s (no return
-- path for either), then respawn at their own spawn coordinates
-- after spawntimesecs (60s, unified in SECTION 15).

UPDATE `creature`
SET `position_x` = 991.17,
    `position_y` = 2864.04,
    `position_z` = 89.89,
    `orientation` = 3.6025
WHERE `guid` = 562546 AND `id` = 57710;


-- ############################################################
-- ## SECTION 17: Yak + cart respawn delay 60s -> 10s
-- ############################################################
-- Supersedes the 60s value from SECTION 15 (user tuning).

UPDATE `creature`
SET `spawntimesecs` = 10
WHERE `guid` IN (562165, 562546) AND `id` IN (57709, 57710);


-- ############################################################
-- ## SECTION 18: Follow target search range 15yd -> 40yd
-- ############################################################
-- Regression from SECTION 16 (cart spawn moved 12.4yd from the yak):
-- the follow list 5771001 resolves its target as CLOSEST_CREATURE
-- 57709 within 15yd. After the yak walks to its bridge-head post the
-- gap reaches ~16.6yd > 15, so the FOLLOW action silently failed and
-- the cart never moved. Widen to 40yd (both the home-set row and the
-- follow row). The eject chain keeps 15yd on purpose (cart trails the
-- yak at 5yd at arrival; tighter range avoids stealing another
-- player's cart when two quests run side by side).

UPDATE `smart_scripts`
SET `target_param2` = 40
WHERE `source_type` = 9
  AND `entryorguid` = 5771001
  AND `target_type` = 19
  AND `target_param1` = 57709;


-- ############################################################
-- ## SECTION 19: Cart 57710 spawn point reverted (supersedes 16)
-- ############################################################
-- User decision: keep the original bridge-head spawn (3.6yd from the
-- yak). SECTION 18's 40yd follow range stays - harmless with the
-- original layout, and protects against future spawn tweaks.

UPDATE `creature`
SET `position_x` = 979.069,
    `position_y` = 2863.87,
    `position_z` = 87.9043,
    `orientation` = 4.7822
WHERE `guid` = 562546 AND `id` = 57710;


-- ############################################################
-- ## SECTION 20: Cart 57710 not despawning at the lead point
-- ############################################################
-- Symptom: at the lead point the yak despawns + respawns at home,
-- but the cart stays. NOT caused by the follow state itself
-- (ForceDespawn clears movement generators - a following creature
-- despawns fine).
-- Root cause: the cart's despawn chain is PASSIVE. It only starts
-- when the cart is HIT by spell 50630 (SPELLHIT_TARGET = 31). The
-- yak casts 50630 at CLOSEST_CREATURE 57710 within 15yd; with
-- follow lag the trailing cart is frequently beyond 15yd the moment
-- waypoint 18 / path-end fire, so both casts whiff, the cart never
-- receives the kick and keeps "following" a yak that despawns.
-- This fork's constraints (verified in SmartScript.cpp):
--   * SMART_ACTION_FORCE_DESPAWN (41) acts on `me` ONLY - the yak
--     cannot remote-despawn the cart via a target list;
--   * SMART_ACTION_STOP_FOLLOW (205) exists and acts on `me`;
--   * SMART_ACTION_CALL_TIMED_ACTIONLIST (80) DOES accept target
--     lists (SetScript9 runs the list on the target).
-- Fix:
--   a) yak link chain id11 -> id13: invoke despawn actionlist
--      5771002 on the closest 57710 within 40yd. The list runs ON
--      the cart: STOP_FOLLOW, then ForceDespawn 5s (respawn at its
--      home per creature.spawntimesecs = 10).
--   b) cart's own 50630-spellhit chain now also releases the follow
--      before the delayed despawn (LINK cascade 11 -> 12).
-- Re-follow needs no change: the next boarding (event 27) reruns
-- actionlist 5771001 which re-issues FOLLOW; a respawned cart is a
-- fresh instance anyway.
-- Requires: .reload smart_scripts (hot reload, no restart).

-- a) yak: cascade id11 -> id13
UPDATE `smart_scripts`
SET `link` = 13
WHERE `source_type` = 0 AND `entryorguid` = -562165 AND `id` = 11;

DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = -562165 AND `id` = 13;

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (-562165, 0, 13, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0,
     80, 5771002, 2, 0, 0, 0, 0, 19, 57710, 40, 0, 0, 0, 0, 0, 0,
     'Nourished Yak - Link - Run Cart Despawn List 5771002 on Closest 57710 (40yd)');

-- the despawn actionlist (runs ON the cart)
DELETE FROM `smart_scripts`
WHERE `source_type` = 9 AND `entryorguid` = 5771002;

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (5771002, 9, 0, 0, 0, 0, 100, 0, 100, 100, 0, 0, 0,
     205, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Cart Despawn List - Stop Following the Yak'),
    (5771002, 9, 1, 0, 0, 0, 100, 0, 200, 200, 0, 0, 0,
     41, 5000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Cart Despawn List - Force Despawn (5s) -> respawn at home (spawntimesecs=10)');

-- b) cart: release follow before the delayed despawn (cascade 11 -> 12)
DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = 57710 AND `id` IN (11, 12);

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`,
     `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (57710, 0, 11, 12, 61, 0, 100, 0, 0, 0, 0, 0, 0,
     205, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - Link - Stop Following the Yak'),
    (57710, 0, 12, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0,
     41, 5000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
     'Delivery Cart - Link - Force Despawn (5s)');

-- keep comments accurate (lead point id changed 14 -> 18 in SECTION 13)
UPDATE `smart_scripts`
SET `comment` = 'Nourished Yak - Reached Lead Point 18 - Cast Eject Passengers on Cart'
WHERE `source_type` = 0 AND `entryorguid` = -562165 AND `id` = 1;
