-- Fix the "Where is Shin?" gossip option of Widow Greenpaw (55368) so
-- quest 29723 "The Jade Witch" (Jade Forest) can complete per the
-- Blizzard-default logic.
--
-- Blizzard flow: talk to Widow Greenpaw (55368) -> select "Where is Shin?"
-- (menu 55368 / option 0) -> SmartAI fires SMART_EVENT_GOSSIP_SELECT and
-- runs SET_FACTION 16 (hostile) + TALK + CLOSE_GOSSIP -> kill her ->
-- normal kill credit Player::KilledMonsterCredit(55368) matches
-- quest_objective 264528 (MONSTER, ObjectID 55368, Amount 1).
--
-- Current DB state that broke this:
--   1. `creature_template`.`gossip_menu_id` for entry 55368 was 0, so the
--      core served the global default menu (MenuID 0) and the "Where is
--      Shin?" option never appeared.  The hostile faction change therefore
--      never triggered, leaving the quest stuck for Horde players (faction
--      template 1034 is friendly to Horde).  Alliance players can still
--      brute-force it by killing her directly.
--   2. `gossip_menu_option_locale` carried a broken zhCN override
--      ("哪里is 阿信？") that masked the option text for zhCN clients;
--      the correct zhCN text is "阿信呢？" (broadcast text 53908).
--
-- Requires a worldserver restart (creature_template and the locale tables
-- are loaded at startup; there is no runtime reload for them).

-- 1) Attach the "Where is Shin?" gossip menu to Widow Greenpaw.
UPDATE `creature_template` SET `gossip_menu_id` = 55368 WHERE `entry` = 55368;

-- 2) Repair the zhCN option text (was a mixed "哪里is 阿信？").
UPDATE `gossip_menu_option_locale` SET `OptionText` = '阿信呢？'
 WHERE `MenuID` = 55368 AND `OptionID` = 0 AND `Locale` = 'zhCN';
