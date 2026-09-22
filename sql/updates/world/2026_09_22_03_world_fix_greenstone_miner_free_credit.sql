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
-- Requires a worldserver restart (smart_scripts is loaded at startup).
UPDATE `smart_scripts` SET `target_type` = 7
 WHERE `entryorguid` = 56464 AND `source_type` = 0 AND `id` = 0
   AND `event_type` = 64 AND `action_type` = 33 AND `action_param1` = 56464;
