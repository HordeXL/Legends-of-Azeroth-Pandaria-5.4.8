-- Fix quest 29929 "Trapped!" - freeing Greenstone Miners never counted.
--
-- Creature 56464 (Greenstone Miner) is the objective target of quest 29929
-- (quest_objective 255454: MONSTER / ObjectID 56464 / Amount 8).  Its only
-- SmartAI row credits that objective from the gossip-hello event:
--   event 64 (SMART_EVENT_GOSSIP_HELLO) -> action 33 (CALL_KILLEDMONSTER 56464)
-- but it targeted SMART_TARGET_VICTIM (2), i.e. the creature's current victim.
-- The miner is a friendly NPC that never enters combat, so GetVictim() is always
-- null, GetTargets() returns an empty list and no player was ever credited -
-- the counter stayed at 0/8 no matter how many miners were clicked.
--
-- Credit the player who opened the gossip instead
-- (SMART_TARGET_ACTION_INVOKER = 7).  This is the only row of its kind in the
-- database (event 64 + action 33 + target 2), and 10 miner spawns exist for the
-- required 8 credits.
--
-- The miner also had no "freed" state at all, so the same spawn could be
-- clicked over and over to fill all 8 credits.  Disable its gossip flag once it
-- has been freed (same pattern the rescue NPCs of this quest chain use, e.g.
-- SMART_ACTION_SET_NPC_FLAG 0 on the Scared Pandaren Cub 55267).  The spawn is
-- shared, so the miner is freed once per respawn cycle (spawntimesecs = 60)
-- rather than once per player - SmartAI is bound to the creature entry and
-- cannot track individual spawns per player.
--
-- Requires a worldserver restart (smart_scripts is loaded at startup).
UPDATE `smart_scripts` SET `target_type` = 7
 WHERE `entryorguid` = 56464 AND `source_type` = 0 AND `id` = 0
   AND `event_type` = 64 AND `action_type` = 33 AND `action_param1` = 56464;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 56464 AND `source_type` = 0 AND `id` = 1;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(56464, 0, 1, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 81, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gossip Hello - Remove gossip flag (miner freed)');

-- Clearing the gossip flag alone leaves the spawn standing there forever
-- (the flag is a runtime value and nothing restores it), so also despawn the
-- freed miner: Creature::ForcedDespawn marks it dead and removes it, after
-- which it follows the normal respawn cycle (creature.spawntimesecs = 60 s),
-- i.e. the miner disappears ~5 s after being freed and reappears 60 s later,
-- ready to be freed again.  Same pattern as the Scared Pandaren Cub 55267.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 56464 AND `source_type` = 0 AND `id` = 2;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(56464, 0, 2, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 41, 5000, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Gossip Hello - Despawn freed miner (respawns per spawntimesecs)');
