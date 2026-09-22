-- Fix the "Scared Pandaren Cub" rescue dialogue that never credited
-- quest 29716 "The Double Hozen Dare" (Jade Forest, Dawn's Blossom).
--
-- Symptom: talking to a Scared Pandaren Cub (55267) never advanced the
-- objective "营救熊猫人儿童" (quest_objective 262315: MONSTER, ObjectID 55267,
-- Amount 6), so the quest could never be completed.
--
-- Root cause: the cub's rescue script is a SmartAI gossip-select script
-- (SMART_EVENT_GOSSIP_SELECT, menu 55267, option 0).  Its first action is
-- SMART_ACTION_INVOKER_CAST spell 103181, whose effect 0 is
-- SPELL_EFFECT_KILL_CREDIT (misc value 55267) - that is what credits the
-- objective through Player::KilledMonsterCredit(55267).
-- That script can only ever run when the player selects menu 55267, but
-- `creature_template`.`gossip_menu_id` for entry 55267 was 0.  With menu 0 the
-- core builds the global default gossip menu (gossip_menu_option.MenuID = 0),
-- whose entries all require vendor/trainer flags the cub does not have, so the
-- cub offered an empty gossip window and the script never fired.
--
-- Related: the option text was stored double encoded (CP850-mangled UTF-8),
-- and the menu had no gossip_menu/npc_text row, so the client fell back to
-- DEFAULT_GOSSIP_MESSAGE (npc_text 16777215, "Greetings, $n.").
--
-- Apply notes: a worldserver restart is required. `gossip_menu_id` is read from
-- creature_template and `npc_text` has no runtime reload command, so `.reload
-- creature_template 55267` + `.reload gossip_menu` alone would leave the new
-- greeting row unloaded until the next full start.

-- 1) Attach the rescue gossip menu to the cub.
UPDATE `creature_template` SET `gossip_menu_id` = 55267 WHERE `entry` = 55267;
UPDATE `world`.`creature_template` SET `npcflag` = 1 WHERE `entry` = 55267;

-- 2) Restore the option text.  The base table carries the authentic English
--    line (broadcast text 53675, the line Blizzard uses for this very cub -
--    it sits in the same dialogue batch as 53683 "That Jade Witch is super
--    spooky."), and the zhCN client is served through
--    `gossip_menu_option_locale`, which previously carried the CP850-mangled
--    text and overrode the base table.  The removed mojibake row is kept in
--    `backup_gossip_menu_option_locale_55267_20260922`.
UPDATE `gossip_menu_option` SET `OptionText` = "It's safe now. You can come down."
 WHERE `MenuID` = 55267 AND `OptionID` = 0;

DELETE FROM `gossip_menu_option_locale` WHERE `MenuID` = 55267;
CREATE TABLE IF NOT EXISTS `backup_gossip_menu_option_locale_55267_20260922` AS
  SELECT * FROM `gossip_menu_option_locale` WHERE 0;
DELETE FROM `backup_gossip_menu_option_locale_55267_20260922`;
INSERT INTO `backup_gossip_menu_option_locale_55267_20260922`
  (`MenuID`, `OptionID`, `Locale`, `OptionText`, `BoxText`)
VALUES (55267, 0, 'zhCN',
  CONVERT(0xC3BEC384E29691C395C2A3C2BFC395C380E29693C3BEE29597C385C395C2ABC3ABC395C3A0C2BFC2B4E2959DC3AEC3B5C2A2C3A1C395C385C2BBC3B5E29597C391C3B5C2A9C3AFC2B5C398C391C3B5E29591C3A5 USING utf8mb4), NULL);

INSERT INTO `gossip_menu_option_locale`
  (`MenuID`, `OptionID`, `Locale`, `OptionText`, `BoxText`)
VALUES (55267, 0, 'zhCN', '现在已经安全，你可以下来了', NULL);

-- 3) Give the menu a proper greeting instead of the generic fallback.
--    Broadcast text 58046 ("I want my mommy." / zhCN "我要妈妈。") is the
--    scared pandaren cub line from the same Blizzard dialogue batch as
--    58045/58047, which the cub already uses in creature_text.
DELETE FROM `gossip_menu` WHERE `MenuID` = 55267;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`, `VerifiedBuild`) VALUES
(55267, 9000099, 0);

DELETE FROM `npc_text` WHERE `ID` = 9000099;
INSERT INTO `npc_text` (`ID`, `Text0_0`, `Text0_1`, `BroadcastTextID0`, `Probability0`, `VerifiedBuild`) VALUES
(9000099, 'I want my mommy.', 'I want my mommy.', 58046, 1, 0);
