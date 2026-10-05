-- Cleansing Drak'Tharon (30120): the MoP Image of Drakuru can offer the
-- original replacement interaction when the player has lost Drakuru's Elixir.

UPDATE `creature_template`
SET `npcflag` = `npcflag` | 1,
    `gossip_menu_id` = 900020,
    `AIName` = 'SmartAI'
WHERE `entry` = 58149;

DELETE FROM `gossip_menu` WHERE `MenuID` = 900020;
INSERT INTO `gossip_menu` (`MenuID`, `TextID`, `VerifiedBuild`)
VALUES (900020, 12998, 0);

DELETE FROM `gossip_menu_option` WHERE `MenuID` = 900020;
INSERT INTO `gossip_menu_option`
(`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`,
 `OptionType`, `OptionNpcflag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`,
 `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`)
VALUES
(900020, 0, 0, 'I need another of your elixirs, Drakuru.', 27286,
 1, 1, 0, 0, 0, 0, '', 0, 0);

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 15
  AND `SourceGroup` = 900020
  AND `SourceEntry` = 0;

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
 `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
 `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
 `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(15, 900020, 0, 0, 0, 9, 0, 30120, 0, 0, 0, 0, 0, '',
 'Show replacement option while Cleansing Drak''Tharon is active'),
(15, 900020, 0, 0, 0, 2, 0, 35797, 1, 1, 1, 0, 0, '',
 'Show replacement option only if Drakuru''s Elixir is missing');

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 58149
  AND `source_type` = 0
  AND `id` IN (0, 1);

INSERT INTO `smart_scripts`
(`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
 `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`,
 `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`,
 `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`,
 `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`,
 `target_y`, `target_z`, `target_o`, `comment`)
VALUES
(58149, 0, 0, 1, 62, 0, 100, 0, 900020, 0, 0, 0, 0,
 85, 50021, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
 'Image of Drakuru - Replacement option - Invoker casts Replace Drakuru''s Elixir'),
(58149, 0, 1, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0,
 72, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0,
 'Image of Drakuru - Replacement option - Close gossip');
