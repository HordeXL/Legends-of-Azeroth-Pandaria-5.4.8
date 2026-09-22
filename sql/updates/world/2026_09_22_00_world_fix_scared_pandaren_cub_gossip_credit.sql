-- Quest 29716, The Double Hozen Dare: rescuing Scared Pandaren Cubs (55267).
-- The gossip-select SmartAI already casts 103181 for kill credit, but the
-- creature has no gossip flag or menu, so players cannot select its option.
-- A worldserver restart is required after applying this update.

UPDATE `creature_template`
SET `gossip_menu_id` = 55267, `npcflag` = `npcflag` | 1
WHERE `entry` = 55267;

-- Use the English broadcast line by default and provide the Chinese locale.
UPDATE `gossip_menu_option`
SET `OptionText` = 'It''s safe now.  You can come down.'
WHERE `MenuID` = 55267 AND `OptionID` = 0;

DELETE FROM `gossip_menu_option_locale`
WHERE `MenuID` = 55267 AND `OptionID` = 0 AND `Locale` = 'zhCN';
INSERT INTO `gossip_menu_option_locale`
    (`MenuID`, `OptionID`, `Locale`, `OptionText`, `BoxText`)
VALUES (55267, 0, 'zhCN', '现在已经安全，你可以下来了', NULL);

DELETE FROM `gossip_menu` WHERE `MenuID` = 55267;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`, `VerifiedBuild`)
VALUES (55267, 9000099, 0);

DELETE FROM `npc_text` WHERE `ID` = 9000099;
INSERT INTO `npc_text`
    (`ID`, `Text0_0`, `Text0_1`, `BroadcastTextID0`, `Probability0`, `VerifiedBuild`)
VALUES (9000099, 'I want my mommy.', 'I want my mommy.', 58046, 1, 0);
