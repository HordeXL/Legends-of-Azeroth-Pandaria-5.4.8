-- Fix quest 30495 "Love's Labor" (爱的劳动): the jade delivery never credited.
-- Jade Forest, the great statuary.
--
-- Blizzard flow: Foreman Raike (59391) sends the player off with the jade
-- shipment; the player carries it to four foremen around / on the statue -
-- Historian Dinh (59395), Surveyor Sawa (59401), Kitemaster Shoku (59392) and
-- Taskmaster Emi (59397, directing production up on the statue) - and talks
-- to each to hand over the jade.  Each delivery credits the matching
-- quest_objective (253077..253080: MONSTER, ObjectID = the NPC entry,
-- Amount 1) through Player::KilledMonsterCredit.
--
-- Symptom: the quest stuck at 0/4 - talking to a foreman never advanced the
-- count.  Three independent defects were found and are fixed below:
--
--  1) All four foremen had npcflag = 0.  The client can only open the hello
--     interaction on a creature whose UNIT_FIELD_NPC_FLAGS carries
--     UNIT_NPC_FLAG_GOSSIP (WorldSession::HandleGossipHelloOpcode resolves
--     the target with GetNPCIfCanInteractWith(guid, UNIT_NPC_FLAG_GOSSIP)
--     and bails out otherwise), so right-clicking a foreman did nothing:
--     no gossip hello was ever sent and the SmartAI never fired.
--
--  2) Kitemaster Shoku's delivery credit used a fragile chain: event 62
--     (SMART_EVENT_GOSSIP_SELECT, menu 59392 option 0) -> action 85
--     (SMART_ACTION_INVOKER_CAST spell 114210, effect 1 =
--     SPELL_EFFECT_KILL_CREDIT misc 59392).  It only fired after the client
--     opened a gossip menu AND the player clicked "deliver the jade" AND the
--     menu/gossipListId indices matched.  On top of that (after fix 1) the
--     menu did not even attach: `creature_template`.`gossip_menu_id` was 0
--     and the menu had no `gossip_menu`/`npc_text` row, so the client fell
--     back to DEFAULT_GOSSIP_MESSAGE with an empty window.
--
--  3) The other three foremen use the reliable pattern that was verified
--     working in-game: event 64 (SMART_EVENT_GOSSIP_HELLO, fires on
--     right-click/greet) -> action 33 (SMART_ACTION_CALL_KILLEDMONSTER with
--     their own entry, target type 17 = SMART_TARGET_PLAYER_RANGE 0..100).
--     No menu, no spell, no option click - talking is enough.  Shoku has been
--     brought onto the same path.
--
-- Shoku's gossip menu itself is kept ("I have the jade shipment." /
-- "将我送往青龙寺.") because option 1 is a real secondary feature: it lets
-- the player ask Shoku to fly them up to Fei (56784) on top of the statue
-- (SMART_EVENT_GOSSIP_SELECT option 1 -> teleport), used by other content in
-- the same area.
--
-- Apply notes: a worldserver restart is required.  creature_template.npcflag
-- and smart_scripts are cached at startup (per-entry `.reload
-- creature_template` works for npcflag), while npc_text has no runtime reload
-- command, so a full restart is the reliable path.
--
-- ============================================================================
-- 1) Enable the GOSSIP interaction on all four foremen.  None of them is a
--    vendor or trainer (npc_vendor / npc_trainer are empty for these
--    entries), so no other flags have to be preserved.
-- ============================================================================
UPDATE `creature_template` SET `npcflag` = 1 WHERE `entry` IN (59392, 59395, 59401);
UPDATE `creature_template` SET `npcflag` = 1 WHERE `entry` = 59397;

-- ============================================================================
-- 2) Attach Shoku's delivery gossip menu and restore its texts.
--    - gossip_menu_id so the client actually displays menu 59392;
--    - option texts: the base table carries the English lines, the zhCN
--      client is served through `gossip_menu_option_locale` (both had been
--      stored CP850-mangled, e.g. option 0 `Õ░åþÄëþƒ│...` -> 将玉石给大师卓续);
--    - a proper greeting row so the window no longer falls back to
--      DEFAULT_GOSSIP_MESSAGE.  Broadcast text 58451 is the line Shoku
--      already carries in creature_text.
-- ============================================================================
UPDATE `creature_template` SET `gossip_menu_id` = 59392 WHERE `entry` = 59392;

UPDATE `gossip_menu_option` SET `OptionText` = "I have the jade shipment."
 WHERE `MenuID` = 59392 AND `OptionID` = 0;
UPDATE `gossip_menu_option` SET `OptionText` = "Fly me up, Shoku."
 WHERE `MenuID` = 59392 AND `OptionID` = 1;

DELETE FROM `gossip_menu_option_locale` WHERE `MenuID` = 59392;
INSERT INTO `gossip_menu_option_locale` (`MenuID`, `OptionID`, `Locale`, `OptionText`, `BoxText`) VALUES
(59392, 0, 'zhCN', '将玉石给大师卓续', NULL),
(59392, 1, 'zhCN', '将我送往青龙寺.', NULL);

DELETE FROM `gossip_menu` WHERE `MenuID` = 59392;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`, `VerifiedBuild`) VALUES
(59392, 9000101, 0);

DELETE FROM `npc_text` WHERE `ID` = 9000101;
INSERT INTO `npc_text` (`ID`, `Text0_0`, `Text0_1`, `BroadcastTextID0`, `Probability0`, `VerifiedBuild`) VALUES
(9000101, 'It''s about time we got another shipment. I heard they were having trouble at the mines, but our work cannot wait.', NULL, 58451, 1, 0);

-- ============================================================================
-- 3) Unify Shoku's delivery credit with the other three foremen: hello event
--    -> CALL_KILLEDMONSTER, byte-compatible with 59395/59397/59401.
--    The old menu-select spell-cast chain (ids 0/1/2) is dropped; the
--    transport option (id 3, event 62 option 1 -> teleport to Fei) is kept.
-- ============================================================================
DELETE FROM `smart_scripts` WHERE `entryorguid` = 59392 AND `source_type` = 0 AND `id` IN (0, 1, 2);

DELETE FROM `smart_scripts` WHERE `entryorguid` = 59392 AND `source_type` = 0 AND `id` = 4;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(59392, 0, 4, 0, 64, 0, 100, 0, 0, 0, 0, 0, 0, 33, 59392, 0, 0, 0, 0, 0, 17, 0, 100, 0, 0, 0, 0, 0, 0, 'On gossip hello - credit jade delivery (same as other delivery NPCs)');
