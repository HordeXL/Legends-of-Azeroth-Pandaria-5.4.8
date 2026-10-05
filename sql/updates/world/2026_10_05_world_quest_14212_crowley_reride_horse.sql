-- Quest 14212 "Sacrifices": make the parked re-ride horse (44429) mountable
--
-- Symptom: after the scripted ride ends at the cathedral, re-clicking the
-- parked "Crowley's Horse" (44429, standing at -1539,1570 = path 35231's last
-- waypoint) failed to mount. Its spellclick 82992 only summoned 44428, which
-- is an empty shell in this DB (no VehicleId, no SAI, no spellclick) - a dead
-- retail chain.
--
-- Fix: promote 44429 itself to a full rideable horse (same treatment as
-- 35231):
--   1) creature_template: VehicleId 0 -> 463 (vehicle kit + SPELLCLICK
--      cursor), AIName -> SmartVehicleAI.
--   2) npc_spellclick_spells: 82992 -> 46598 (cast_flags=1, player mounts).
--   3) Clone 35231's creature SAI rows onto 44429 (incl. the SpellHit(46598)
--      -> start-list row, wp jumps/quotes, wp33 dismount, Crowley despawn).
--      Both horses share the timed list 3523100 (all actions are SELF-
--      relative) and the same waypoint path 35231.
--   4) Crowley's mount action (list 3523000) now targets OWNER_OR_SUMMONER
--      (target_type 23) instead of "nearest 35231 within 10yd", so he boards
--      whichever horse summoned him (35231 for the first ride, 44429 for
--      re-rides) even if the other horse stands nearby.

UPDATE `creature_template` SET `VehicleId`=463, `AIName`='SmartVehicleAI'
WHERE `entry`=44429 AND `VehicleId`=0;

UPDATE `npc_spellclick_spells` SET `spell_id`=46598
WHERE `npc_entry`=44429 AND `spell_id`=82992;

UPDATE `smart_scripts` SET `target_type`=23, `target_param1`=0, `target_param2`=0, `target_param3`=0
WHERE `source_type`=9 AND `entryorguid`=3523000 AND `id`=0 AND `action_type`=11 AND `action_param1`=47020;

DELETE FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid`=44429;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
SELECT 44429, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`
FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid`=35231;
