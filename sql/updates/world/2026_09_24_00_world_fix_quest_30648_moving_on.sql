-- Quest 30648 "Moving On" (勇往直前, Kun-Lai Summit 昆莱山 -> Valley of the Four Winds 四风谷)
--
-- Final behaviour: accept the quest from Fei (59899), talk to her again to
-- complete the objective ("Travel to Valley of the Four Winds"), then select
-- the gossip option "前往四风谷" to be teleported down into the valley.
--
-- Blizzard default mechanics as implemented in this core:
--   * Quest flags 0x150000 = AUTO_COMPLETE | DISPLAY_COMPLETION_TEXT | AUTO_SUBMIT,
--     so there is no creature_questender row - the quest is auto submitted
--     (Quest::IsTurnIn() == true, QuestDef.cpp).
--   * The single objective is QUEST_OBJECTIVE_MONSTER on invisible trigger
--     creature 59692 "All Purpose Bunny (JLR)" (no spawn in `creature`; credit
--     only ever comes from SAI).
--   * smart_scripts on Fei (59899):
--       - event 64 GOSSIP_HELLO  -> action 33 KILL_CREDIT 59692 on the invoker
--         (SmartAI::OnGossipHello runs BEFORE PrepareGossipMenu, see
--         NPCHandler.cpp:501, so the objective completes on the same talk).
--       - event 62 GOSSIP_SELECT -> action 62 TELEPORT_TO map 870
--         (529.507, -706.552, 247.248) = the flight to Valley of the Four Winds.
--
-- History / root cause:
--   * The gossip option was stored under MenuID = 59899 while Fei's
--     creature_template.gossip_menu_id = 13646.  This core resolves the menu id
--     from creature_template (Player::GetDefaultGossipMenuForSource) and the
--     client echoes that id back in CMSG_GOSSIP_SELECT_OPTION, so:
--       - an option under menu 59899 is never displayed (menu 13646 has none), and
--       - the SAI GOSSIP_SELECT event required sender = 59899 which never
--         matches the client-sent menuId 13646 (SmartScript.cpp
--         "e.event.gossip.sender != var0" early return).
--     Net effect: the teleport (the "flight") never happened.
--   * OptionText was stored as mojibake ("ÕëìÕ¥ÇÕøøÚúÄÞ░À" - unrecoverable
--     double-encoding); the intended text matches the objective description:
--     "前往四风谷".
--   * OptionNpcflag = 1 (GOSSIP) while Fei only has npcflag = 2 (QUESTGIVER);
--     this build never reads OptionNpcflag, but 3 keeps the row semantically
--     correct.
--
-- Notes:
--   * No conditions were added to the option on purpose: the core's
--     CONDITION_QUESTTAKEN only matches QUEST_STATUS_INCOMPLETE, but the
--     GOSSIP_HELLO credit already flips the quest to QUEST_STATUS_COMPLETE
--     before the menu is built, so a quest-taken condition would hide the
--     option exactly when it is needed.
--   * Fei (59899) is the only user of gossip menu 13646, so moving the option
--     affects nobody else.
--
-- Apply notes: worldserver restart, or ".reload gossip_menu_option" /
-- ".reload smart_scripts" if the running build supports them.

-- 1) Move the flight option onto Fei's real gossip menu and repair the text.
UPDATE `gossip_menu_option` SET
  `MenuID`        = 13646,
  `OptionText`    = '前往四风谷',
  `OptionNpcflag` = 3
WHERE `MenuID` = 59899 AND `OptionID` = 0;

-- 2) Make the SAI gossip-select event match the menu id the client echoes back.
UPDATE `smart_scripts` SET
  `event_param1` = 13646
WHERE `entryorguid` = 59899 AND `source_type` = 0 AND `id` = 0
  AND `event_type` = 62 AND `action_type` = 62;
