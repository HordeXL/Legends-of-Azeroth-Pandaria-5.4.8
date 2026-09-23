-- Jade Forest statue works: quest 30495 "Love's Labor" (爱的劳动) jade
-- deliveries together with quest 29932 "The Temple of the Jade Serpent"
-- (青龙寺) kite ride.  Consolidated single update for both quests (they share
-- Kitemaster Shoku 59392 and the statue-area foremen).
--
-- 30495: Foreman Raike (59391) sends the player to four foremen - Historian
-- Dinh (59395), Surveyor Sawa (59401), Kitemaster Shoku (59392) and Taskmaster
-- Emi (59397).  Talking to each credits its objective on the gossip-hello
-- interaction (all four need the GOSSIP npcflag for the client to interact at
-- all, and Shoku also needs his menu attached).
--
-- 29932: after taking the quest, the player talks to Kitemaster Shoku and
-- picks "将我送往青龙寺.".  Shoku SUMMONS a kite on the spot, the player is
-- mounted on it automatically, and the kite flies from the statue base up to
-- the temple entrance, landing in front of Elder Sage Wind-Yi (57242,
-- 大贤者易风).  Talking to Wind-Yi completes objective 256152 (kill credit
-- 57290); the quest is handed in to Elder Sage Rain-Zhu (56782, 大贤者朱雨)
-- inside the temple.
--
-- Design notes:
--   * The kite is NOT a permanent spawn - it is summoned by the gossip option
--     and removes itself after the ride (5 s after landing, plus a safety
--     timer).  The old permanent spawn (creature guid 4000121) is deleted.
--   * Auto-mount follows the pattern already proven in this database for
--     "summoned/clicked vehicle -> the player rides it" (Stormhoof 30388,
--     Aviana's Guardian 40720, Uplifting Draft 55685): SMART_ACTION_INVOKER_CAST
--     with ride spell 46598 and castFlags 0 (normal cast) - SMARTCAST_TRIGGERED
--     skips the CONTROL_VEHICLE aura apply path and the player never boards.
--   * Objective credit for 29932 goes to Wind-Yi OUTSIDE the entrance; the
--     earlier misplaced credit on Rain-Zhu (56782) is removed.
--
-- Apply notes: worldserver restart required (creature_template, creature,
-- creature_template_movement, waypoints, smart_scripts, conditions,
-- creature_text and npc_text are all loaded at startup).

-- ============================================================================
-- 0) Delivery foremen setup shared by both quests: GOSSIP interaction for all
--    four, and Shoku's gossip menu + greeting.
-- ============================================================================
UPDATE `creature_template` SET `npcflag` = 1 WHERE `entry` IN (59392, 59395, 59401);
UPDATE `creature_template` SET `npcflag` = 1 WHERE `entry` = 59397;

UPDATE `creature_template` SET `gossip_menu_id` = 59392 WHERE `entry` = 59392;

UPDATE `gossip_menu_option` SET `OptionText` = "Fly me up, Shoku."
 WHERE `MenuID` = 59392 AND `OptionID` = 1;

DELETE FROM `gossip_menu_option_locale` WHERE `MenuID` = 59392;
INSERT INTO `gossip_menu_option_locale` (`MenuID`, `OptionID`, `Locale`, `OptionText`, `BoxText`) VALUES
(59392, 1, 'zhCN', '将我送往青龙寺.', NULL);

DELETE FROM `gossip_menu` WHERE `MenuID` = 59392;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`, `VerifiedBuild`) VALUES
(59392, 9000101, 0);

DELETE FROM `npc_text` WHERE `ID` = 9000101;
INSERT INTO `npc_text` (`ID`, `Text0_0`, `Text0_1`, `BroadcastTextID0`, `Probability0`, `VerifiedBuild`) VALUES
(9000101, 'It''s about time we got another shipment. I heard they were having trouble at the mines, but our work cannot wait.', NULL, 58451, 1, 0);

-- ============================================================================
-- 1) Gossip menu 59392: option 1 shows while 29932 is in progress.  The
--    obsolete option 0 (30495 jade delivery) is dropped - that delivery
--    credits on the gossip-hello interaction now (section 2).
-- ============================================================================
UPDATE `conditions` SET `ConditionTypeOrReference` = 9
 WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 59392
   AND `SourceEntry` = 1 AND `ConditionTypeOrReference` = 28 AND `ConditionValue1` = 29932;

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 59392 AND `SourceEntry` = 0;
DELETE FROM `gossip_menu_option_locale` WHERE `MenuID` = 59392 AND `OptionID` = 0;
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 59392 AND `OptionID` = 0;

-- ============================================================================
-- 2) Kitemaster Shoku (59392) script: summon the kite, mount the player,
--    close the gossip, and keep the 30495 delivery credit on hello.
-- ============================================================================
DELETE FROM `creature_text` WHERE `CreatureID` = 59392 AND `GroupID` = 1;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(59392, 1, 0, 'Hop on the kite, friend - it will carry you up to the temple.', 12, 0, 100, 0, 0, 0, 0, 0, 0, 'Kitemaster Shoku - kite ride prompt');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 59392 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(59392, 0, 3, 5, 62, 0, 100, 0, 59392, 1, 0, 0, 0, 12, 69058, 3, 120000, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 1, 0, 'Gossip Select - summon the kite at the invoker'),
(59392, 0, 4, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 33, 59392, 0, 0, 0, 0, 0, 17, 0, 100, 0, 0, 0, 0, 0, 0, 'On gossip hello - credit jade delivery (30495)'),
(59392, 0, 5, 6, 61, 0, 100, 0, 0, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Link - Close Gossip'),
(59392, 0, 6, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 85, 46598, 0, 0, 0, 0, 0, 19, 69058, 0, 30, 0, 0, 0, 0, 0, 'Link - Invoker rides the kite (normal cast, closest kite)');

-- ============================================================================
-- 3) The kite template (69058), cloned from Tak-Tak's Kite (68720) rig:
--    vehicle 2608, display 41903, selectable (unit_flags 0 - it may also be
--    clicked), speed_run 4 (~90 s ride over the 739 yd path).
-- ============================================================================
DELETE FROM `creature_template` WHERE `entry` = 69058;
INSERT INTO `creature_template` (`entry`,`difficulty_entry_1`,`difficulty_entry_2`,`difficulty_entry_3`,`difficulty_entry_4`,`difficulty_entry_5`,`KillCredit1`,`KillCredit2`,`name`,`femaleName`,`subname`,`IconName`,`gossip_menu_id`,`minlevel`,`maxlevel`,`exp`,`exp_unk`,`faction`,`npcflag`,`npcflag2`,`speed_walk`,`speed_run`,`scale`,`rank`,`mindmg`,`maxdmg`,`dmgschool`,`attackpower`,`dmg_multiplier`,`BaseAttackTime`,`RangeAttackTime`,`unit_class`,`unit_flags`,`unit_flags2`,`dynamicflags`,`family`,`trainer_type`,`trainer_class`,`trainer_race`,`minrangedmg`,`maxrangedmg`,`rangedattackpower`,`type`,`type_flags`,`type_flags2`,`lootid`,`pickpocketloot`,`skinloot`,`resistance1`,`resistance2`,`resistance3`,`resistance4`,`resistance5`,`resistance6`,`spell1`,`spell2`,`spell3`,`spell4`,`spell5`,`spell6`,`spell7`,`spell8`,`PetSpellDataId`,`VehicleId`,`mingold`,`maxgold`,`AIName`,`MovementType`,`HoverHeight`,`Health_mod`,`Mana_mod`,`Mana_mod_extra`,`Armor_mod`,`RacialLeader`,`questItem1`,`questItem2`,`questItem3`,`questItem4`,`questItem5`,`questItem6`,`movementId`,`RegenHealth`,`VignetteID`,`TrackingQuestID`,`mechanic_immune_mask`,`flags_extra`,`ScriptName`,`VerifiedBuild`) VALUES
(69058, 0, 0, 0, 0, 0, 0, 0, 'Shoku''s Kite', 0, NULL, NULL, 0, 90, 90, 4, 0, 35, 16777216, 0, 1, 4, 1, 0, 14666, 24933, 0, 42299, 1, 2000, 2000, 1, 0, 2048, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2608, 0, 0, 'SmartAI', 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, '', 18414);

DELETE FROM `creature_template_model` WHERE `CreatureID` = 69058;
INSERT INTO `creature_template_model` (`CreatureID`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(69058, 41903, 1, 1);

-- Flight mode: a creature only flies when CanFly() is true, which comes from
-- creature_template_movement.Flight (CreatureFlightMovementType.CanFly = 2).
DELETE FROM `creature_template_movement` WHERE `CreatureId` = 69058;
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`, `InteractionPauseTimer`) VALUES
(69058, 0, 0, 2, 0, NULL, NULL, NULL);

-- Clicking the kite also mounts the player (Ride Vehicle Hardcoded, seat 0):
-- a fallback for the automatic mount from the gossip option.
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` = 69058;
INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`) VALUES
(69058, 46598, 1, 0);

-- The kite is summoned on demand - remove the old permanent spawn.
DELETE FROM `creature` WHERE `guid` = 4000121;

-- ============================================================================
-- 4) Flight path: statue base up to the temple entrance, landing in front of
--    Wind-Yi (995.63, -2447.68, 168.70).
-- ============================================================================
DELETE FROM `waypoints` WHERE `entry` = 69058;
INSERT INTO `waypoints` (`entry`, `pointid`, `position_x`, `position_y`, `position_z`, `orientation`, `delay`, `point_comment`) VALUES
(69058, 1, 856, -1914, 70, 0, 0, NULL),
(69058, 2, 880, -1924, 75, 0, 0, NULL),
(69058, 3, 901, -1932, 80, 0, 0, NULL),
(69058, 4, 921, -1940, 86, 0, 0, NULL),
(69058, 5, 942, -1951, 93, 0, 0, NULL),
(69058, 6, 968, -1967, 102, 0, 0, NULL),
(69058, 7, 987, -1983, 107, 0, 0, NULL),
(69058, 8, 1000, -2004, 115, 0, 0, NULL),
(69058, 9, 1013, -2029, 126, 0, 0, NULL),
(69058, 10, 1023, -2051, 130, 0, 0, NULL),
(69058, 11, 1031, -2073, 135, 0, 0, NULL),
(69058, 12, 1041, -2096, 140, 0, 0, NULL),
(69058, 13, 1049, -2118, 145, 0, 0, NULL),
(69058, 14, 1055, -2138, 150, 0, 0, NULL),
(69058, 15, 1059, -2167, 161, 0, 0, NULL),
(69058, 16, 1053, -2195, 164, 0, 0, NULL),
(69058, 17, 1039, -2237, 172, 0, 0, NULL),
(69058, 18, 1024, -2277, 178, 0, 0, NULL),
(69058, 19, 1013, -2309, 182, 0, 0, NULL),
(69058, 20, 997, -2349, 188, 0, 0, NULL),
(69058, 21, 993, -2401, 184, 0, 0, NULL),
(69058, 22, 988, -2453, 170, 0, 0, NULL);

-- ============================================================================
-- 5) Kite AI: the player boards -> fly the path; the final waypoint (22) is
--    the landing spot in front of Wind-Yi, where the kite despawns 5 s later.
--    A 60 s timer is kept as a safety net if movement is ever interrupted.
-- ============================================================================
DELETE FROM `smart_scripts` WHERE `entryorguid` = 69058 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(69058, 0, 0, 0, 27, 0, 100, 0, 0, 0, 0, 0, 0, 53, 1, 69058, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Passenger boarded - start the kite ride'),
(69058, 0, 1, 0, 40, 0, 100, 0, 22, 0, 0, 0, 0, 41, 5000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Waypoint 22 reached - despawn the kite after 5s'),
(69058, 0, 2, 0, 27, 0, 100, 0, 0, 0, 0, 0, 0, 67, 1, 60000, 60000, 0, 0, 100, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Passenger boarded - safety despawn timer 60s'),
(69058, 0, 3, 0, 59, 0, 100, 0, 1, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Timed event 1 - force despawn (safety net)');

-- ============================================================================
-- 6) Objective credit goes to Elder Sage Wind-Yi (57242), the talk target
--    OUTSIDE the temple entrance.  Remove the earlier misplaced credit from
--    Rain-Zhu (56782, the in-temple turn-in NPC).
-- ============================================================================
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 57242;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 57242 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(57242, 0, 0, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 33, 57290, 0, 0, 0, 0, 0, 17, 0, 100, 0, 0, 0, 0, 0, 0, 'On gossip hello - credit talk to Elder Sage Wind-Yi (29932)');

DELETE FROM `smart_scripts` WHERE `entryorguid` = 56782 AND `source_type` = 0 AND `id` = 1;
