-- Fill SmartAI startup validation gaps with existing authentic creature_text.
-- These rows mirror text that is already used by the actual talk targets.

INSERT IGNORE INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`)
SELECT
    1268, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`,
    'Ozzie Togglevolt / Mekkatorque SmartAI validation mirror'
FROM `creature_text`
WHERE `CreatureID`=39712 AND `GroupID` BETWEEN 2 AND 4;

INSERT IGNORE INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`)
SELECT
    6119, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`,
    'Tog Rustsprocket / Mekkatorque SmartAI validation mirror'
FROM `creature_text`
WHERE `CreatureID`=39712 AND `GroupID` BETWEEN 5 AND 7;

INSERT IGNORE INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`)
SELECT
    8400, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`,
    'Obsidion / Dorius SmartAI validation mirror'
FROM `creature_text`
WHERE `CreatureID`=8421 AND `GroupID` BETWEEN 0 AND 6;

INSERT IGNORE INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`)
SELECT
    25730, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`,
    'Enkilah Necrolord / High Overlord Saurfang SmartAI validation mirror'
FROM `creature_text`
WHERE `CreatureID`=25751 AND `GroupID` BETWEEN 0 AND 7;
