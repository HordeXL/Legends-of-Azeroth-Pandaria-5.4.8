-- Restore the Blizzard kite-ride mechanic for quest 29932 "The Temple of the
-- Jade Serpent" (青龙寺) and fix the objective credit on the correct NPC.
--
-- Quest flow (Blizzard): after taking 29932 from Foreman Raike (59391), the
-- player talks to Kitemaster Shoku (59392).  Shoku keeps a kite parked by his
-- side; the player clicks the kite (SPELLCLICK -> Ride Vehicle 46598), rides
-- it along a flight path that ascends from the statue base up to the temple
-- entrance, and lands right in front of Elder Sage Wind-Yi (57242, 大贤者易风,
-- outside the entrance).  Talking to Wind-Yi completes objective 256152
-- (MONSTER / ObjectID 57290 "Kill Credit: Breadcrumb to Jade Temple"); the
-- player then enters the temple and talks to Elder Sage Rain-Zhu (56782,
-- 大贤者朱雨) to turn the quest in.
--
-- Fixes in this update:
--
--  1) Objective credit was wired to the WRONG NPC.  Objective 256152 credits
--     on talking to Wind-Yi (57242, the sage OUTSIDE the entrance); the
--     previous fix accidentally put the GOSSIP_HELLO->CALL_KILLEDMONSTER(57290)
--     script on Rain-Zhu (56782, the IN-temple turn-in NPC) instead.  That
--     script is removed here and the credit is put on Wind-Yi (57242) using
--     the same "[Kill]OnSpeak" pattern as every other talk-to NPC.
--
--  2) The kite option was a plain teleport.  Menu option 1 on Shoku (59392,
--     "将我送往青龙寺.") used to TELEPORT the player to the temple straight
--     away (SMART_ACTION_TELEPORT).  Restored to the Blizzard mechanics: a
--     kite vehicle (VehicleId 2608, the same kite rig as Tak-Tak's/Fennie's
--     Kite; display 41903) is parked in front of Shoku.  The player clicks it
--     and rides the flight path to the landing spot in front of Wind-Yi,
--     where the kite despawns and the rider steps off.  The menu option is
--     kept (visible while quest 29932 is active, per the earlier conditions
--     fix) and now simply prompts the player to take the kite.
--
-- The kite ride reuses the exact pattern the server already validates for the
-- jade cart (56508): SmartAI event 27 (PASSENGER_BOARDED) stores the rider
-- and starts the `waypoints` path; the final waypoint is the landing spot, and
-- event 58 (WAYPOINT_ENDED) despawns the kite so the passenger steps off.
--
-- Apply notes: worldserver restart required (creature_template, creature,
-- npc_spellclick_spells, waypoints, smart_scripts and creature_text are all
-- startup-loaded).

-- ============================================================================
-- 1) Objective credit on the correct sage: Wind-Yi (57242, quest 29932 talk
--    target outside the temple entrance).  npcflag already carries GOSSIP
--    (3 = GOSSIP|QUESTGIVER); make him SmartAI and credit kill credit 57290.
-- ============================================================================
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 57242;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 57242 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(57242, 0, 0, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 33, 57290, 0, 0, 0, 0, 0, 17, 0, 100, 0, 0, 0, 0, 0, 0, 'On gossip hello - credit talk to Elder Sage Wind-Yi (quest 29932)');

-- Remove the wrongly placed credit from Rain-Zhu (56782, in-temple turn-in
-- NPC).  Keep his original REWARD_QUEST say script (id 0).
DELETE FROM `smart_scripts` WHERE `entryorguid` = 56782 AND `source_type` = 0 AND `id` = 1;

-- ============================================================================
-- 2) The kite ride, mirroring the validated jade-cart pattern (56508).
-- ============================================================================
-- 2a) Kite template: clone of Tak-Tak's Kite (68720, vehicle 2608, display
--     41903) with a proper name, SPELLCLICK flag and SmartAI.
INSERT INTO `creature_template` (`entry`,`difficulty_entry_1`,`difficulty_entry_2`,`difficulty_entry_3`,`difficulty_entry_4`,`difficulty_entry_5`,`KillCredit1`,`KillCredit2`,`name`,`femaleName`,`subname`,`IconName`,`gossip_menu_id`,`minlevel`,`maxlevel`,`exp`,`exp_unk`,`faction`,`npcflag`,`npcflag2`,`speed_walk`,`speed_run`,`scale`,`rank`,`mindmg`,`maxdmg`,`dmgschool`,`attackpower`,`dmg_multiplier`,`BaseAttackTime`,`RangeAttackTime`,`unit_class`,`unit_flags`,`unit_flags2`,`dynamicflags`,`family`,`trainer_type`,`trainer_class`,`trainer_race`,`minrangedmg`,`maxrangedmg`,`rangedattackpower`,`type`,`type_flags`,`type_flags2`,`lootid`,`pickpocketloot`,`skinloot`,`resistance1`,`resistance2`,`resistance3`,`resistance4`,`resistance5`,`resistance6`,`spell1`,`spell2`,`spell3`,`spell4`,`spell5`,`spell6`,`spell7`,`spell8`,`PetSpellDataId`,`VehicleId`,`mingold`,`maxgold`,`AIName`,`MovementType`,`HoverHeight`,`Health_mod`,`Mana_mod`,`Mana_mod_extra`,`Armor_mod`,`RacialLeader`,`questItem1`,`questItem2`,`questItem3`,`questItem4`,`questItem5`,`questItem6`,`movementId`,`RegenHealth`,`VignetteID`,`TrackingQuestID`,`mechanic_immune_mask`,`flags_extra`,`ScriptName`,`VerifiedBuild`) VALUES
(69058, 0, 0, 0, 0, 0, 0, 0, 'Shoku''s Kite', 0, NULL, NULL, 0, 90, 90, 4, 0, 35, 16777216, 0, 1, 1.14286, 1, 0, 14666, 24933, 0, 42299, 1, 2000, 2000, 1, 33554944, 2048, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2608, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, '', 18414);

-- 2b) Kite model binding.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 69058;
INSERT INTO `creature_template_model` (`CreatureID`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(69058, 41903, 1, 1);

-- 2c) Park the kite next to Shoku (858.99, -1913.10, 63.55).
DELETE FROM `creature` WHERE `guid` = 4000121;
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `phaseId`, `phaseGroup`, `modelid`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `spawntimesecs_max`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `npcflag2`, `unit_flags`, `unit_flags2`, `dynamicflags`, `ScriptName`, `walk_mode`, `VerifiedBuild`) VALUES
(4000121, 69058, 870, 0, 0, 1, 1, 0, 0, 0, 0, 854.5, -1908.5, 63.6, 2.28, 300, 0, 0, 0, 51300, 0, 0, 0, 0, 0, 0, 0, '', 0, 0);

-- 2d) Clicking the kite starts the ride.
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` = 69058;
INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`) VALUES
(69058, 46598, 1, 0);

-- 2e) Flight path: statue base up to the temple entrance, landing right in
--     front of Wind-Yi (995.63, -2447.68, 168.70).  Smooth ascent 64 -> 169.
DELETE FROM `waypoints` WHERE `entry` = 69058;
INSERT INTO `waypoints` (`entry`, `pointid`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `point_comment`) VALUES
(69058, 1, 854.5, -1908.5, 64, 0, 0, NULL),
(69058, 2, 860, -1918, 68, 0, 0, NULL),
(69058, 3, 868, -1932, 73, 0, 0, NULL),
(69058, 4, 876, -1948, 78, 0, 0, NULL),
(69058, 5, 884, -1966, 83, 0, 0, NULL),
(69058, 6, 892, -1986, 88, 0, 0, NULL),
(69058, 7, 900, -2008, 93, 0, 0, NULL),
(69058, 8, 908, -2032, 98, 0, 0, NULL),
(69058, 9, 916, -2058, 103, 0, 0, NULL),
(69058, 10, 924, -2086, 108, 0, 0, NULL),
(69058, 11, 932, -2116, 113, 0, 0, NULL),
(69058, 12, 940, -2148, 118, 0, 0, NULL),
(69058, 13, 948, -2182, 123, 0, 0, NULL),
(69058, 14, 956, -2218, 128, 0, 0, NULL),
(69058, 15, 964, -2256, 133, 0, 0, NULL),
(69058, 16, 972, -2296, 138, 0, 0, NULL),
(69058, 17, 980, -2338, 143, 0, 0, NULL),
(69058, 18, 986, -2380, 148, 0, 0, NULL),
(69058, 19, 990, -2418, 153, 0, 0, NULL),
(69058, 20, 993, -2444, 158, 0, 0, NULL),
(69058, 21, 995.6, -2447.68, 163, 0, 0, NULL),
(69058, 22, 995.6, -2447.68, 168.7, 0, 0, NULL);

-- 2f) Kite AI: passenger boarded -> remember them and start the path; the
--     final waypoint (22) is the landing spot in front of Wind-Yi, so the
--     kite despawns there (passenger steps off).  No kill credit here - the
--     objective is credited when the player talks to Wind-Yi (57242).
DELETE FROM `smart_scripts` WHERE `entryorguid` = 69058 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(69058, 0, 0, 0, 27, 0, 100, 0, 0, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Passenger boarded - remember the rider'),
(69058, 0, 1, 0, 27, 0, 100, 0, 0, 0, 0, 0, 0, 53, 1, 69058, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Passenger boarded - start the kite ride'),
(69058, 0, 2, 0, 58, 0, 100, 0, 22, 69058, 0, 0, 0, 41, 3000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Waypoint 22 reached - despawn the kite');

-- ============================================================================
-- 3) Shoku's menu option 1 must no longer teleport.  Keep the option (visible
--    while 29932 is active) but make it prompt the player to take the kite.
--    Rewrite Shoku's GOSSIP_SELECT option-1 script (id 3): link id 3 -> 5 so
--    the say is followed by closing the gossip window.  id 4 (the hello
--    delivery credit) is left untouched.
-- ============================================================================
DELETE FROM `creature_text` WHERE `CreatureID` = 59392 AND `GroupID` = 1;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(59392, 1, 0, 'Hop on the kite, friend - it will carry you up to the temple.', 12, 0, 100, 0, 0, 0, 0, 0, 0, 'Kitemaster Shoku - kite ride prompt');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 59392 AND `source_type` = 0 AND `id` IN (3, 5);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(59392, 0, 3, 5, 62, 0, 100, 0, 59392, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gossip Select - kite prompt say'),
(59392, 0, 5, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Link - Close Gossip');
