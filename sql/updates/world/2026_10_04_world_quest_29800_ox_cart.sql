-- ============================================================
-- 2026-10-04  Quest 29800 "New Allies" — Ox Cart Ride (consolidated)
--
-- Merges the six iteration scripts (ox_cart_ride / ox_cart_follow /
-- ox_cart_polish / rope_instant_fix / sai_reorder_fix /
-- rope_bind_yak) into the idempotent final state.
--
-- Features (all verified in-game):
--   * Player clicks cart 57741 -> boards (spellclick 46598), quest
--     objective type 3 (TALKTO) credits on first click (official).
--   * On boarding: 800ms SET_DATA 1/1 -> lead yak 57743 starts the
--     20-point lead path (run); 900ms cart FOLLOWs 5yd behind at
--     180deg (mirror of proven 29775 / 57709+57710 pattern);
--     1200/1400ms rope visuals.
--   * At point 20 (Temple of Five Dawns): yak ejects cart, cart
--     spellhit chain credits quest 29800 to vehicle passengers
--     (requires SpecialFlags bit 2), ejects player, stops follow,
--     both NPCs despawn and respawn at home in 5s.
--   * Rope visuals are a CONSTANT cart<->yak state regardless of
--     quest: respawn list casts on yak with retries at 3s/3.2s;
--     conditions (source 13 SPELL_IMPLICIT_TARGET) lock the rope
--     spells' implicit targets to entry 57743.
--
-- Root causes fixed along the way (see comments inline):
--   1. Official SAI had no waypoint data and yak never moved.
--   2. Link rows MUST use event_type=61 (SmartScript.cpp:2545).
--   3. Non-instant casts inside a timed actionlist stall the whole
--      serial list (UpdateTimer delays CAST actions while the unit
--      is UNIT_STATE_CASTING) -> all rope casts use TRIGGERED(2)
--      + INTERRUPT_PREVIOUS(1), and signal/follow actions are
--      ordered BEFORE casts.
--   4. TARGET_UNIT_NEARBY_ENTRY (38) does NO entry filtering in
--      this core -> rope bound to the nearest unit (Delivery Cart
--      Tender 57712) when the yak had not respawned yet.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Lead path 5774000: 20-point measured route to Temple of Five Dawns
-- ------------------------------------------------------------
DELETE FROM `waypoints` WHERE `entry`=5774000;
INSERT INTO `waypoints` (`entry`,`pointid`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`) VALUES
(5774000, 1,  279.59, 3882.98,  75.61, 0.1431, 0),
(5774000, 2,  312.67, 3886.51,  79.09, 6.2809, 0),
(5774000, 3,  420.18, 3887.41,  79.26, 6.1553, 0),
(5774000, 4,  448.50, 3876.18,  79.47, 5.2050, 0),
(5774000, 5,  465.92, 3841.63,  80.18, 4.7377, 0),
(5774000, 6,  467.00, 3805.47,  80.95, 4.6670, 0),
(5774000, 7,  463.30, 3753.40,  82.72, 4.3175, 0),
(5774000, 8,  454.97, 3732.33,  82.12, 4.0583, 0),
(5774000, 9,  431.81, 3702.42,  81.42, 3.8698, 0),
(5774000,10,  403.95, 3675.67,  81.42, 4.6199, 0),
(5774000,11,  402.94, 3636.17,  90.11, 4.8908, 0),
(5774000,12,  413.19, 3623.68,  92.75, 0.1588, 0),
(5774000,13,  444.81, 3631.86,  84.74, 6.2260, 0),
(5774000,14,  514.60, 3627.47,  88.17, 5.5545, 0),
(5774000,15,  551.76, 3586.67,  93.35, 6.0571, 0),
(5774000,16,  591.52, 3582.17,  97.48, 1.1445, 0),
(5774000,17,  605.17, 3622.05, 119.81, 0.3866, 0),
(5774000,18,  628.96, 3630.66, 133.77, 5.4995, 0),
(5774000,19,  660.97, 3600.18, 146.97, 6.2731, 0),
(5774000,20,  743.34, 3601.71, 140.53, 0.0213, 0); -- temple stop

-- ------------------------------------------------------------
-- 2) Creature templates: SmartAI on cart and yak; 5s respawn delay
-- ------------------------------------------------------------
UPDATE `creature_template` SET `AIName`='SmartAI' WHERE `entry` IN (57741,57743);
UPDATE `creature` SET `spawntimesecs`=5 WHERE `id` IN (57741,57743);

-- ------------------------------------------------------------
-- 3) SAI: final chain (cart 57741 / yak 57743 + 3 actionlists)
-- ------------------------------------------------------------
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (57741,57743)
 OR (`source_type`=9 AND `entryorguid` IN (5774100,5774101,5774301));

INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
-- Cart 57741: boarding chain + eject spellhit chain + respawn rope
(57741, 0, 0, 1, 27, 0, 100, 0, 0, 0, 0, 0, 0, 19, 16384, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Delivery Cart (29800) - On Passenger Boarded - Remove Disable Move Flag'),
(57741, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 80, 5774101, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Delivery Cart (29800) - Link - Start Ride Script 5774101'),
(57741, 0, 2, 3, 31, 0, 100, 0, 50630, 0, 0, 0, 0, 15, 29800, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Delivery Cart (29800) - On Eject Spellhit From Yak - Quest Credit 29800 To Vehicle Passengers'),
(57741, 0, 3, 4, 61, 0, 100, 0, 0, 0, 0, 0, 0, 11, 50630, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Delivery Cart (29800) - Link - Cast Eject Passengers (Self)'),
(57741, 0, 4, 5, 61, 0, 100, 0, 0, 0, 0, 0, 0, 205, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Delivery Cart (29800) - Link - Stop Following the Yak'),
(57741, 0, 5, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 41, 5000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Delivery Cart (29800) - Link - Force Despawn (5s) -> Respawn At Home'),
(57741, 0, 6, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 80, 5774100, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Delivery Cart (29800) - On Respawn - Restore Rope Visual (List 5774100)'),
-- Yak 57743: lead path, arrival eject, despawn cascade
(57743, 0, 0, 0, 38, 0, 100, 0, 1, 1, 0, 0, 0, 53, 1, 5774000, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Nourished Yak (29800) - On Data Set 1/1 - Start Lead Path 5774000 (Run, No Repeat)'),
(57743, 0, 1, 3, 40, 0, 100, 0, 20, 5774000, 0, 0, 0, 11, 50630, 0, 0, 0, 0, 0, 19, 57741, 15, 0, 0, 0, 0, 0, 'Nourished Yak (29800) - Reached Lead Point 20 (Temple) - Cast Eject Passengers on Closest Cart (15yd)'),
(57743, 0, 2, 3, 61, 0, 100, 0, 0, 0, 0, 0, 0, 41, 5000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Nourished Yak (29800) - Link - Force Despawn (5s) -> Respawn At Home'),
(57743, 0, 3, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 80, 5774301, 2, 0, 0, 0, 0, 19, 57741, 40, 0, 0, 0, 0, 0, 'Nourished Yak (29800) - Link - Run Cart Despawn List 5774301 on Closest Cart (40yd)'),
(57743, 0, 4, 2, 58, 0, 100, 0, 0, 5774000, 0, 0, 0, 11, 50630, 0, 0, 0, 0, 0, 19, 57741, 15, 0, 0, 0, 0, 0, 'Nourished Yak (29800) - Lead Path Ended (Backup) - Cast Eject Passengers on Closest Cart'),
-- Actionlist 5774100: rope visual restore on cart respawn (with retries until yak is up)
(5774100, 9, 0, 0, 0, 0, 100, 0, 500, 500, 0, 0, 0, 11, 120795, 3, 0, 0, 0, 0, 19, 57743, 40, 0, 0, 0, 0, 0, 'Cart Respawn Script (29800) - Ox Cart Rope Left 120795 on Yak (Triggered, Persistent Aura)'),
(5774100, 9, 1, 0, 0, 0, 100, 0, 700, 700, 0, 0, 0, 11, 111810, 3, 0, 0, 0, 0, 19, 57743, 40, 0, 0, 0, 0, 0, 'Cart Respawn Script (29800) - Ox Cart Rope Right 111810 on Yak (Triggered)'),
(5774100, 9, 2, 0, 0, 0, 100, 0, 3000, 3000, 0, 0, 0, 11, 120795, 3, 0, 0, 0, 0, 19, 57743, 40, 0, 0, 0, 0, 0, 'Cart Respawn Script (29800) - Rope Left retry @3s (waits for yak respawn)'),
(5774100, 9, 3, 0, 0, 0, 100, 0, 3200, 3200, 0, 0, 0, 11, 111810, 3, 0, 0, 0, 0, 19, 57743, 40, 0, 0, 0, 0, 0, 'Cart Respawn Script (29800) - Rope Right retry @3.2s (waits for yak respawn)'),
-- Actionlist 5774101: ride script (signals/follow FIRST - immune to casting-state stall; rope casts after with flag 3)
(5774101, 9, 0, 0, 0, 0, 100, 0, 800, 800, 0, 0, 0, 45, 1, 1, 0, 0, 0, 0, 19, 57743, 40, 0, 0, 0, 0, 0, 'Cart Ride Script (29800) - Signal Yak (DATA 1/1) FIRST - immune to casting-state stall'),
(5774101, 9, 1, 0, 0, 0, 100, 0, 900, 900, 0, 0, 0, 29, 5, 180, 0, 0, 0, 0, 19, 57743, 40, 0, 0, 0, 0, 0, 'Cart Ride Script (29800) - Follow Lead Yak (5yd Behind, 180deg) SECOND'),
(5774101, 9, 2, 0, 0, 0, 100, 0, 1200, 1200, 0, 0, 0, 11, 120795, 3, 0, 0, 0, 0, 19, 57743, 40, 0, 0, 0, 0, 0, 'Cart Ride Script (29800) - Ox Cart Rope Left 120795 (Triggered+InterruptPrevious bypasses casting-state delay)'),
(5774101, 9, 3, 0, 0, 0, 100, 0, 1400, 1400, 0, 0, 0, 11, 111810, 3, 0, 0, 0, 0, 19, 57743, 40, 0, 0, 0, 0, 0, 'Cart Ride Script (29800) - Ox Cart Rope Right 111810 (Triggered+InterruptPrevious)'),
-- Actionlist 5774301: cart cleanup when yak despawns
(5774301, 9, 0, 0, 0, 0, 100, 0, 100, 100, 0, 0, 0, 205, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Cart Despawn List (29800) - Stop Following the Yak'),
(5774301, 9, 1, 0, 0, 0, 100, 0, 200, 200, 0, 0, 0, 41, 5000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Cart Despawn List (29800) - Force Despawn (5s) -> Respawn At Home');

-- ------------------------------------------------------------
-- 4) Quest 29800: SpecialFlags |= 2 (FLAGS_EXPLORATION_OR_EVENT)
--    required for action 15 quest credit on vehicle passengers
-- ------------------------------------------------------------
UPDATE `quest_template_addon` SET `SpecialFlags`=`SpecialFlags`|2 WHERE `ID`=29800;

-- ------------------------------------------------------------
-- 5) Rope spells 120795/111810: lock implicit target
--    (TARGET_UNIT_NEARBY_ENTRY does NO entry filtering in this
--    core) to Nourished Yak 57743 so the rope never binds to
--    nearby bystanders (e.g. Delivery Cart Tender 57712)
-- ------------------------------------------------------------
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=13 AND `SourceEntry` IN (120795,111810);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,`ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`) VALUES
(13, 1, 120795, 0, 0, 31, 0, 3, 57743, 0, 0, 0, 0, '', '29800 Ox Cart Rope Left: implicit target must be Nourished Yak 57743'),
(13, 1, 111810, 0, 0, 31, 0, 3, 57743, 0, 0, 0, 0, '', '29800 Ox Cart Rope Right: implicit target must be Nourished Yak 57743');
