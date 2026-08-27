-- Rollback for 2026_08_27_02_world_quest_26228_livin_the_life.sql.

DELETE FROM `spell_script_names` WHERE `spell_id` = 79275;
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` = 42500;
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 79262;

UPDATE `creature_template` SET `unit_flags` = 0, `VehicleId` = 899, `AIName` = 'SmartAI' WHERE `entry` = 42500;
UPDATE `creature_template` SET `unit_flags` = 0, `AIName` = '' WHERE `entry` = 42515;
UPDATE `creature_template` SET `type_flags` = 0, `unit_class` = 1, `unit_flags` = 0, `AIName` = 'SmartAI' WHERE `entry` = 42492;
DELETE FROM `creature_template_addon` WHERE `entry` = 42515;

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (42500, 42515, 42492) AND `source_type` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (4250000, 4251500, 4251501, 4249200) AND `source_type` = 9;
INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`,
     `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`,
     `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (42492, 0, 0, 1, 54, 0, 100, 0, 0, 0, 0, 0, 0, 11, 64446, 3, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'q26228 - on summon teleport effect'),
    (42492, 0, 1, 2, 1, 0, 100, 1, 20000, 20000, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'q26228 - txt1'),
    (42492, 0, 2, 3, 1, 0, 100, 1, 36000, 36000, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'q26228 - txt3'),
    (42492, 0, 3, 4, 1, 0, 100, 1, 52000, 52000, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'q26228 - txt6'),
    (42492, 0, 4, 5, 1, 0, 100, 1, 68000, 68000, 0, 0, 0, 1, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'q26228 - txt8'),
    (42492, 0, 5, 0, 1, 0, 100, 1, 76000, 76000, 0, 0, 0, 1, 4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'q26228 - txt9'),
    (42500, 0, 0, 1, 54, 0, 100, 0, 0, 0, 0, 0, 0, 11, 79263, 1, 4, 0, 0, 0, 1, 0, 0, 0, 0, -9845.65, 1396.7, 37.26, 0.57, 'q26228 - summon Gluntok'),
    (42500, 0, 1, 2, 61, 0, 100, 0, 0, 0, 0, 0, 0, 12, 34867, 1, 120000, 0, 0, 0, 8, 0, 0, 0, 0, -9822.84, 1410.34, 36.35, 3.53, 'q26228 - summon Shadowy figure'),
    (42500, 0, 2, 0, 1, 0, 100, 1, 100000, 100000, 1000, 1000, 0, 11, 79275, 3, 0, 0, 0, 0, 23, 0, 0, 0, 0, 0, 0, 0, 0, 'q26228 - kilcredit at the end of event');

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceEntry` IN (79273, 79290, 79292, 79294, 79297, 79279, 79283, 79284, 79287);

DELETE FROM `creature_text_locale`
WHERE `CreatureID` IN (42492, 42515) AND `Locale` = 'ruRU';

DELETE FROM `creature_text` WHERE `CreatureID` = 34867;
INSERT INTO `creature_text`
    (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`,
     `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
    (34867, 0, 0, 'Sad... Is this the life that you had hoped for, Glubtok? Running two-bit extortion operations out of a cave?', 12, 0, 0, 0, 0, 0, 0, 42419, 0, 'q26228 - txt 2'),
    (34867, 1, 0, 'Oh will you? Do you dare cross that line and risk your life?', 12, 0, 0, 0, 0, 0, 0, 42421, 0, 'q26228 - txt 4'),
    (34867, 2, 0, 'You may attempt to kill me - and fail - or you may take option two.', 12, 0, 0, 0, 0, 0, 0, 42423, 0, 'q26228 - txt 5'),
    (34867, 3, 0, 'You join me and I shower wealth and power upon you.', 12, 0, 0, 0, 0, 0, 0, 42424, 0, 'q26228 - txt 7'),
    (34867, 4, 0, 'I thought you''d see it my way.', 12, 0, 0, 0, 0, 0, 0, 42428, 0, 'q26228 - txt 10'),
    (34867, 5, 0, 'I will call for you when the dawning is upon us.', 12, 0, 0, 0, 0, 0, 0, 42429, 0, 'q26228 - txt 11');
