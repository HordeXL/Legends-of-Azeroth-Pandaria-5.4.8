-- ============================================================================
-- Quest 29776 "Morning Breeze Village" (晨息村) - temple whirlwind ride fix
-- Applied: 2026-10-03
-- ============================================================================
-- Live-DB audit found why accepting the quest never carried the player to the
-- top of the Temple of Five Dawns:
--
--   1) The C++ script `npc_master_shang_xi_temple` (whirlwind summon +
--      EnterVehicle on quest accept, plus the "back to temple top" gossip
--      fallback) is bound to Master Shang Xi 64530 - a spawn far from the
--      temple.  But 29776 is offered by Master Shang Xi 54786
--      (creature_queststarter), whose only accept-handler was SAI id 15:
--      cast 104396 (Uplifting Draft) on the invoker.
--   2) Even when the draft (55685) spawns, its own "just spawned" SAI row
--      (id 0) casts 46598 (Ride Vehicle Hardcoded) on ITSELF with
--      castFlags = 2 (SMARTCAST_TRIGGERED).  Per the 29932 kite
--      investigation, TRIGGERED casts skip the CONTROL_VEHICLE aura apply
--      and the player never boards - and a self-cast cannot mount anyone.
--      Result: player accepts the quest, nothing happens.
--
-- Fix mirrors the proven 29932 kite pattern (Shoku's Kite 69058):
-- invoker-cast 46598 with castFlags 0 on the closest draft.  Boarding then
-- fires PASSENGER_BOARDED (27) which starts waypoint path 55685 (13 points,
-- spiralling up to 920.45, 3604.77, 254.17 at the temple top), where
-- WAYPOINT_ENDED (58) ejects the passenger (68576) and despawns the draft.
-- Also makes the draft clickable (Ride Vehicle Hardcoded spellclick) so the
-- decorative temple-base draft works as the retail-style "ride back up".
-- ============================================================================

-- ---------------------------------------------------------------------------
-- SECTION 1: quest accept - summon the draft at the player and mount them
-- ---------------------------------------------------------------------------
-- Replaces the dead cast of 104396 (id 15).  Summon type 3
-- (TEMPSUMMON_TIMED_DESPAWN, 120 s) keeps the draft around long enough for
-- the ~40 s ride; invoker-cast 46598 (normal cast, closest draft within
-- 100 yd) puts the player in the vehicle seat, same as the 29932 kite.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 54786 AND `source_type` = 0 AND `id` IN (15, 20, 21);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(54786, 0, 20, 21, 19, 0, 100, 0, 29776, 0, 0, 0, 0, 12, 55685, 3, 120000, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Master Shang Xi - On Accepted Quest 29776 - Summon Uplifting Draft at invoker'),
(54786, 0, 21, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 85, 46598, 0, 0, 0, 0, 0, 19, 55685, 0, 30, 0, 0, 0, 0, 0, 'Link - Invoker rides the draft (normal cast, closest draft)');

-- ---------------------------------------------------------------------------
-- SECTION 2: repair the draft itself
-- ---------------------------------------------------------------------------
-- 2a) Drop the broken self-cast of 46598 (castFlags 2, target SELF): boarding
--     is now handled by the invoker-cast above; the self-cast can never mount
--     anyone and TRIGGERED casts skip the CONTROL_VEHICLE aura path anyway.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 55685 AND `source_type` = 0 AND `id` = 0;

-- 2b) Flight mode CanFly (2), exactly like the proven kite 69058, so the
--     draft reliably follows the elevated waypoint path (currently
--     DisableGravity (1), which also flies, but align with the proven rig).
UPDATE `creature_template_movement` SET `Flight` = 2 WHERE `CreatureId` = 55685;

-- 2c) Make the draft selectable/clickable (drop NOT_SELECTABLE +
--     DISABLE_MOVE, flags = 0 like the kite) - required for the spellclick
--     fallback below and harmless for a pure vehicle creature.
UPDATE `creature_template` SET `unit_flags` = 0 WHERE `entry` = 55685;

-- ---------------------------------------------------------------------------
-- SECTION 3: click-to-ride fallback (retail behaviour)
-- ---------------------------------------------------------------------------
-- Clicking any Uplifting Draft (e.g. the decorative temple-base spawn guid
-- 561696) mounts the player; PASSENGER_BOARDED then starts the ride-up path.
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` = 55685;
INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`) VALUES
(55685, 46598, 1, 0);

-- ---------------------------------------------------------------------------
-- SECTION 4 (live-test iteration): vehicle seat swap
-- ---------------------------------------------------------------------------
-- First live test: boarding succeeded but the player was ejected ~1 s later.
-- Audit of every remaining difference against the proven kite rig (69058)
-- pointed at the vehicle itself: the draft's VehicleId 1800 uses seat 10318
-- (VehicleSeat.dbc flags 0x40112016: UNCONTROLLED, PASSENGER_NOT_SELECTABLE,
-- and NO CAN_ENTER_OR_EXIT), while the working kite uses VehicleId 2608 with
-- seat 12235 (flags 0x4200800F, CAN_ENTER_OR_EXIT set).  Spell duration
-- (46598 = permanent), SpellEffect data, SAI structure, waypoint path and
-- display id all check out identical, so the seat/vehicle rig is the last
-- variable - switch the draft onto the proven kite vehicle.
UPDATE `creature_template` SET `VehicleId` = 2608 WHERE `entry` = 55685;

-- ---------------------------------------------------------------------------
-- SECTION 5 (final): abandon the vehicle ride, teleport on quest accept
-- ---------------------------------------------------------------------------
-- Second live test: boarding succeeded, but the player was still ejected
-- within a second even on the proven kite vehicle rig.  The vehicle path is
-- abandoned entirely:
--
--   * Quest-accept transport is a plain SAI teleport (action 62
--     SMART_ACTION_TELEPORT handles players via Player::TeleportTo): on
--     ACCEPTED_QUEST (19) of 29776, teleport the invoker (target 7) to the
--     temple top (860, 926.58, 3605.33, 251.63, o 3.114 - the same
--     coordinates as the C++ gossip fallback in
--     zone_wandering_island_west.cpp).  Verified in-core that action 62
--     exists and works on players; event 19 + invoker targeting on 54786 was
--     already proven by the earlier summon attempt.  Hot-reloadable via
--     `.reload smart_scripts` - no restart needed.
--     (A temporary Eluna variant, quest_29776_temple_teleport.lua, was
--     superseded by this SAI row and removed.)
--   * The draft repair (SECTION 2) and click-to-ride spellclick (SECTION 3)
--     are KEPT: clicking a decorative draft still rides waypoint path 55685
--     up to the temple top, serving as the retail-style "ride back up".
DELETE FROM `smart_scripts` WHERE `entryorguid` = 54786 AND `source_type` = 0 AND `id` IN (20, 21);
INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(54786, 0, 20, 0, 19, 0, 100, 0, 29776, 0, 0, 0, 0, 62, 860, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 926.58, 3605.33, 251.63, 3.114, 'Master Shang Xi - On Accepted Quest 29776 - Teleport invoker to Temple of Five Dawns top');

-- ---------------------------------------------------------------------------
-- SECTION 6 (root cause): the quest-giving spawn uses per-GUID SAI rows
-- ---------------------------------------------------------------------------
-- Fifth live test (clean restart, rows verified loaded) still produced no
-- talk and no teleport.  Root cause: the temple-base Master Shang Xi spawn
-- guid 561731 (the one players actually accept 29776 from) has FIVE
-- per-GUID rows in smart_scripts (entryorguid = -561731).  SmartAI loads
-- per-GUID rows INSTEAD of entry rows (SmartScript::OnInitialize:
-- GetScript(-guid) falling back to GetScript(entry) only when the guid list
-- is empty), so every entry-based 54786 fix above never applied to this
-- spawn.  Its id 4 row was the retail handler all along:
--   On Accepted Quest 29776 -> cast 104396 (Uplifting Draft, summon spell
--   that auto-mounts the caster) - i.e. the earlier "summon + boarding
--   success" came from this row, not from the entry rows.
-- Fix: convert guid row 4 to the same SAI teleport and add a debug talk
-- link; the entry rows are kept for the other 54786 spawns.
UPDATE `smart_scripts`
SET `action_type` = 62, `action_param1` = 860, `action_param2` = 0, `action_param3` = 0,
    `link` = 0, `target_x` = 926.58, `target_y` = 3605.33, `target_z` = 251.63, `target_o` = 3.114,
    `comment` = 'Master Shang Xi (guid 561731) - On Accepted Quest 29776 - Teleport invoker to Temple of Five Dawns top'
WHERE `entryorguid` = -561731 AND `source_type` = 0 AND `id` = 4;
-- (Verified working in-game 2026-10-03.  A temporary debug talk link row and
--  its creature_text group 99 entry were removed after the successful test.)
