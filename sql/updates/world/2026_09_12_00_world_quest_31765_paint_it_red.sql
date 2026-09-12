-- Quest 31765 "Paint it Red!" (血染滩头!) - Thunder Hold bombardment.
-- Ports the pandaria_5.4.8 (alexkulya) fix, adapted to this repo:
--   1) the clickable Gunship Turrets get the reference data (aimed shot 130973)
--   2) spell_gunship_turret_barrage binding (per-hit quest credit)
--   3) object_visibility so the camp is visible from the turret at all
--   4) SmartAI so the Alliance cannons fire back at the gunship
-- Companion pieces already present here and NOT touched:
--   npc_spellclick_spells 57573 rows for 66674/66676/66677, quest_objective
--   amounts 80/9, removal of the Nazgrim 55135 accept-autocomplete SAI
--   (2026_07_20_05_world_restore_quest_31765_powder_round.sql).
-- Code side: zone_the_jade_forest.cpp carries spell_gunship_turret_barrage;
-- SpellEffect.dbc was binary-patched (130994 impact radius -> 15 yd row 18,
-- the four native KILL_CREDIT2 rows zeroed - our core resolves target 105,
-- so the script is the only credit source, no double counting).

-- =====================================================================
-- 1) Clickable turrets 66674/66676/66677 -> reference config.
-- spell1 130973 ("Crusher Barrage", TRIGGER_MISSILE -> 130994) is cast by the
-- PLAYER: the client attaches the trajectory, so Spell::SelectImplicitTrajTargets
-- works without code. 130163 ("Full Automatic Fire") stays only on 66183, the
-- non-clickable summoned turret. VehicleId 2455 -> seat 11876
-- (VEHICLE_SEAT_FLAG_CAN_ENTER_OR_EXIT | CAN_CONTROL), verified in our DBC.
-- =====================================================================
UPDATE `creature_template`
   SET `VehicleId`  = 2455,
       `spell1`     = 130973,
       `spell2`     = 0,
       `faction`    = 35,
       `unit_flags` = 2048
 WHERE `entry` IN (66674, 66676, 66677);

UPDATE `creature_template`
   SET `spell2` = 0, `unit_flags` = 2048
 WHERE `entry` = 66183;

-- =====================================================================
-- 2) Per-hit quest credit: 130994 damages the impact area; every 66200/66203
-- actually hit grants one credit to the gunner (caster charmer).
-- =====================================================================
DELETE FROM `spell_script_names` WHERE `spell_id` = 130994;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(130994, 'spell_gunship_turret_barrage');

-- =====================================================================
-- 3) Visibility: Visibility.Distance.Continents is 90 here while the whole
-- Thunder Hold camp sits 102-329 yd from the turret - without these rows the
-- player mans a turret over an empty camp. 350 yd covers the farthest object.
-- =====================================================================
DELETE FROM `object_visibility` WHERE `type` = 'Creature' AND `entry` IN
    (66200,66202,66203,66283,66284,66285,66286,66287,66288,66336,
     66348,66395,66477,66554,66555,66556,66647,66648,66649,66650,66651,66654,66948);
INSERT INTO `object_visibility` (`type`,`entry`,`distance`,`active`,`importance`,`comment`) VALUES
('Creature', 66200, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Soldier (q31765 target)'),
('Creature', 66203, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Cannon (q31765 target)'),
('Creature', 66202, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Laborer'),
('Creature', 66284, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Laborer'),
('Creature', 66651, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Laborer'),
('Creature', 66285, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Infantryman (q31767 target)'),
('Creature', 66650, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Infantryman'),
('Creature', 66288, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Sharp-Shooter'),
('Creature', 66647, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Sharp-Shooter'),
('Creature', 66395, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Cannoneer'),
('Creature', 66348, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Armsman'),
('Creature', 66286, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Mender'),
('Creature', 66649, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Mender'),
('Creature', 66287, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Lieutenant'),
('Creature', 66648, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Lieutenant'),
('Creature', 66283, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Captain Doren (q31769 target)'),
('Creature', 66654, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Supplies (q31768 barrels)'),
('Creature', 66948, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Twisted Corpse'),
('Creature', 66554, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Alliance Barricade (q31769 target)'),
('Creature', 66555, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Alliance Barricade (q31769 target)'),
('Creature', 66556, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Alliance Barricade (q31769 target)'),
('Creature', 66336, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Fire Effects Bunny'),
('Creature', 66477, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Cannon Fire Effects Bunny'),
('Creature', 66795, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Hellscream''s Fist - Gunship Fire Bunny');

DELETE FROM `object_visibility` WHERE `type` = 'GameObject' AND `entry` IN
    (215588,215641,215646,215647,215649,215650,215681,215695,215967);
INSERT INTO `object_visibility` (`type`,`entry`,`distance`,`active`,`importance`,`comment`) VALUES
('GameObject', 215649, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Munitions'),
('GameObject', 215650, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Explosives'),
('GameObject', 215646, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Barricade'),
('GameObject', 215647, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Barricade'),
('GameObject', 215681, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Barricade'),
('GameObject', 215967, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Stack of Cannonballs'),
('GameObject', 215641, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Water Barrel'),
('GameObject', 215695, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Barrel of Honeybrew'),
('GameObject', 215588, 350, 0, 'GroundClutter', 'Pandaria - Jade Forest - Thunder Hold - Damaged Thunder Hold Cannon');

-- =====================================================================
-- 4) The Alliance camp shoots back: 66203 shipped with no AI at all.
-- 130717 (muzzle/trail dummy, implicit target 25 - a one-shot cast, not an
-- aura, so it must be cast on a timer). Aimed at a Gunship Turret (66674)
-- because the crew phasemask 67108864 is invisible to the cannons'
-- phasemask 1 (1 & 67108864 = 0, but 1 & 67108865 = 1). SMART_ACTION_CAST
-- needs a real unit, so a fixed position target is not possible.
-- =====================================================================
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 66203;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 66203 AND `source_type` = 0;
INSERT INTO `smart_scripts`
    (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
     `event_param1`,`event_param2`,`event_param3`,`event_param4`,
     `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
     `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
-- SMART_EVENT_UPDATE_OOC(1): initial 1-6 s, then every 4-9 s so the 13
-- cannons drift out of sync instead of firing in one volley.
-- SMART_ACTION_CAST(11) -> SMART_TARGET_CLOSEST_CREATURE(19): entry 66674, maxDist 400.
(66203, 0, 0, 0, 1, 0, 100, 0, 1000, 6000, 4000, 9000, 11, 130717, 0, 0, 0, 0, 0, 19, 66674, 400, 0, 0, 0, 0, 0,
 'Thunder Hold Cannon - out of combat - fire at Hellscream''s Fist');
