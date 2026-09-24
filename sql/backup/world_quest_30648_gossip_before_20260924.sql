-- Backup before fix: Quest 30648 "Moving On" (勇往直前) gossip/SAI repair
-- Taken 2026-09-24 from world DB on 127.0.0.1 (F:/LOA-Pandaria-5.4.8-Release mysql-5.7.44-x64)
--
-- Restores:
--   1) gossip_menu_option: "前往四风谷" option under orphan menu 59899 (OptionText stored mojibake)
--   2) smart_scripts: Fei (59899) GOSSIP_SELECT teleport event with sender=59899 (never matches menu 13646)

-- 1) restore original gossip option
DELETE FROM `gossip_menu_option` WHERE `MenuID` = 13646 AND `OptionID` = 0;
INSERT INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcflag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`) VALUES (59899, 0, 0, _utf8mb4 0xC395C3ABC3ACC395C2A5C387C395C3B8C3B8C39AC3BAC384C39EE29691C380, 0, 1, 1, 0, 0, 0, 0, NULL, 0, 0);

-- 2) restore original SAI gossip-select teleport event
UPDATE `smart_scripts` SET `event_param1` = 59899
WHERE `entryorguid` = 59899 AND `source_type` = 0 AND `id` = 0 AND `event_type` = 62 AND `action_type` = 62;
