-- Implement Toya's free ride for quest 29925 "All We Can Spare" (Jade Forest).
--
-- Blizzard flow: after accepting from Toya (56348) at Dawn's Blossom, talk to
-- him again and pick the option "I'm ready to see Lorewalker Cho." (broadcast
-- text 55718).  Toya then flies you for free along taxi path 3044
-- (Dawn's Blossom node 895 -> Emperor's Omen node 970) past Greenstone
-- Village, where Lorewalker Cho (56345) accepts the Scavenged Jade (76483).
--
-- The completion itself (item objective 255448 -> turn in to Cho) already
-- worked; what was missing is the dialogue/ride.  Toya had gossip_menu_id 0
-- and no SmartAI, so the option never appeared.
--
-- Requires a worldserver restart (creature_template, gossip_menu*, npc_text
-- and smart_scripts are loaded at startup).

-- 1) Attach a gossip menu to Toya.
UPDATE `creature_template` SET `gossip_menu_id` = 56348 WHERE `entry` = 56348;

-- 2) Greeting text: broadcast 63481 ("Hey there, $r. Lorewalker Cho told me
--    aaaaallll about you...", zhCN "嘿，你好啊，$r。游学者周卓把你的事都告诉
--    我了，至少是重要的部分。...").
DELETE FROM `gossip_menu` WHERE `MenuID` = 56348;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`, `VerifiedBuild`) VALUES
(56348, 9000100, 0);

DELETE FROM `npc_text` WHERE `ID` = 9000100;
INSERT INTO `npc_text` (`ID`, `Text0_0`, `BroadcastTextID0`, `Probability0`, `VerifiedBuild`) VALUES
(9000100, 'Hey there, $r. Lorewalker Cho told me aaaaallll about you. Or at least, the important stuff. Folks around here might be a little hesitant around you though so you may want to get on their good side first.', 63481, 1, 0);

-- 3) The ride option (broadcast 55718, "I'm ready to see Lorewalker Cho.").
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 56348 AND `OptionID` = 0;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(56348, 0, 0, 'I''m ready to see Lorewalker Cho.', 55718, 1, 1, 0, 0, 0, 0, '', 0, 0);

-- zhCN text for the option (broadcast 55718 zhCN: "我已经准备好去见游学者周卓了。").
DELETE FROM `gossip_menu_option_locale` WHERE `MenuID` = 56348 AND `OptionID` = 0;
INSERT INTO `gossip_menu_option_locale` (`MenuID`, `OptionID`, `Locale`, `OptionText`, `BoxText`) VALUES
(56348, 0, 'zhCN', '我已经准备好去见游学者周卓了。', NULL);

-- 4) Only show the option while the quest is active (mirrors the existing
--    pattern used for Widow Greenpaw 55368).
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 56348 AND `SourceEntry` = 0 AND `SourceId` = 0 AND `ElseGroup` = 0;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`) VALUES
(15, 56348, 0, 0, 0, 9, 0, 29925, 0, 0, 0, 0, 0);

-- 5) SmartAI: on gossip select, start taxi path 3044 (free flight to
--    Emperor's Omen) for the talking player, then close the dialogue.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 56348 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(56348, 0, 0, 0, 62, 0, 100, 0, 56348, 0, 0, 0, 0, 52, 3044, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gossip Select - Free taxi ride to Emperor''s Omen'),
(56348, 0, 1, 0, 62, 0, 100, 0, 56348, 0, 0, 0, 0, 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Gossip Select - Close Gossip');

-- 6) Toya's template had an empty AIName, so the SmartAI above never ran
--    (the server logged "Creature entry 56348 has SmartAI scripts, but its
--    AIName is not 'SmartAI'").  Fix it, and drop the QUESTTAKEN(29925)
--    condition that hid the ride option while the quest was not active -
--    the Blizzard data has no such condition for Toya, and the ride is
--    harmless without the quest.
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 56348;

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 56348 AND `SourceEntry` = 0 AND `SourceId` = 0 AND `ElseGroup` = 0;
