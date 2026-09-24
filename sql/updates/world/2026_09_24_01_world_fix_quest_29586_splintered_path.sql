-- Fix quest 29586 "The Splintered Path" (崎岖小路) - objective "发现魔古营地 0/1" never completes
-- Applied: 2026-09-24 (world DB on 127.0.0.1, F:/LOA-Pandaria-5.4.8-Release mysql-5.7.44-x64)
--
-- Root cause analysis:
--   quest_objective 258561: type = 0 (QUEST_OBJECTIVE_MONSTER), objectId = 54999 ("Mogu Camp Kill Credit"), amount = 1.
--   Creature 54999 is an invisible kill-credit placeholder (no displayId, unit_flags NOT_SELECTABLE,
--   flags_extra 0x80) and has NO spawn in `creature`, and NOTHING in the DB grants credit 54999:
--     - no smart_scripts action 33 (KILL_CREDIT) with param 54999
--     - no spelleffect_dbc SPELL_EFFECT_KILL_CREDIT (45) with misc 54999
--     - no areatrigger_involvedrelation row for quest 29586
--   => the objective is unreachable: reaching the mogu camp (map 870, ~209, -1413, 77, next to
--      Shao the Defiant 55009, turn-in NPC) does nothing.
--   The client AreaTrigger.dbc has no trigger on map 870 within 80y of the camp, so the
--   DBC/AreaTrigger route would require a client-side patch. DB-only fix instead:
--   spawn the credit bunny at the camp and let SmartAI grant the kill credit on proximity.
--
-- Fix:
--   1) creature_template 54999: AIName = 'SmartAI' (required for smart_scripts to run).
--   2) creature: spawn 54999 at the mogu camp, same position as Shao the Defiant (guid 501419:
--      209.323, -1412.85, 76.9177), static, no wander.
--   3) smart_scripts (entryorguid 54999): UPDATE_OOC heartbeat (2s) -> action 33 KILL_CREDIT 54999
--      on SMART_TARGET_CLOSEST_PLAYER within 20y. KilledMonsterCredit() is a no-op for players
--      without the quest or already credited, so repeated ticks are harmless; turn-in stays at
--      Shao the Defiant (creature_questender quest 29586 = 55009).

-- 1) enable SmartAI on the credit bunny
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 54999 AND IFNULL(`AIName`,'') = '';

-- 2) spawn the invisible credit bunny at the mogu camp
DELETE FROM `creature` WHERE `guid` = 4000120;
INSERT INTO `creature`
  (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`,
   `spawntimesecs`, `wander_distance`, `curhealth`, `curmana`, `MovementType`, `VerifiedBuild`)
VALUES
  (4000120, 54999, 870, 5785, 5857, 1, 1, 209.323, -1412.85, 76.9177, 0,
   300, 0, 1, 0, 0, 18414);

-- 3) proximity kill credit via SmartAI
DELETE FROM `smart_scripts` WHERE `entryorguid` = 54999 AND `source_type` = 0;
INSERT INTO `smart_scripts`
  (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
   `event_param1`, `event_param2`, `event_param3`, `event_param4`,
   `action_type`, `action_param1`, `target_type`, `target_param1`, `comment`)
VALUES
  (54999, 0, 0, 0, 1, 0, 100, 0,
   2000, 2000, 2000, 2000,
   33, 54999, 21, 20,
   'Mogu Camp Kill Credit - OOC heartbeat - Give kill credit 54999 to closest player within 20y (quest 29586 objective 258561)');
