-- Selecting "将我送往青龙寺." from Kitemaster Shoku (59392) should
-- automatically mount the parked kite instead of only prompting.
--
-- Quest 29932 "The Temple of the Jade Serpent" (青龙寺) - the Blizzard flow is:
-- talk to Shoku, pick the kite option, ride the kite to the temple.  The
-- previous update parked Shoku's Kite (69058) beside him with SPELLCLICK and a
-- SmartAI ride (which still works by clicking the kite directly), but the menu
-- option 1 only said a line and closed the gossip.  This update makes the
-- menu option itself trigger the ride.
--
-- Mechanic: the menu option's GOSSIP_SELECT script now chains:
--   say (group 1) -> close gossip -> SMART_ACTION_INVOKER_CAST spell 46598
-- (VEHICLE_SPELL_RIDE_HARDCODED) on the nearby kite (SMART_TARGET_CREATURE_RANGE
-- entry 69058, 0..30 yd).  The player is the invoker of the GOSSIP_SELECT
-- event, so the action makes the PLAYER ride the kite; the kite's existing
-- SmartAI then starts the flight path (event 27 PASSENGER_BOARDED) and lands
-- in front of Elder Sage Wind-Yi (57242), where the objective 256152 is
-- credited on talking to him.  Clicking the kite directly keeps working as a
-- fallback.
--
-- Apply notes: worldserver restart or ".reload smart_scripts" required
-- (smart_scripts is cached at startup).

DELETE FROM `smart_scripts` WHERE `entryorguid` = 59392 AND `source_type` = 0 AND `id` IN (3, 5, 6);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(59392, 0, 3, 5, 62, 0, 100, 0, 59392, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gossip Select - kite prompt say'),
(59392, 0, 5, 6, 61, 0, 100, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Link - Close Gossip'),
(59392, 0, 6, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 85, 46598, 2, 0, 0, 0, 0, 9, 69058, 0, 30, 0, 0, 0, 0, 0, 'Link - Invoker rides the kite (Ride Vehicle Hardcoded)');
