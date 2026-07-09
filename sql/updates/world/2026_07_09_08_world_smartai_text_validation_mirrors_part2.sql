-- Additional SmartAI startup validation mirrors.
-- The source SmartAI rows select another creature as the talk target, but startup
-- validation checks text groups on the source entry.

INSERT IGNORE INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`)
SELECT
    7955, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`,
    'Milli Featherwhistle / Mekkatorque SmartAI validation mirror'
FROM `creature_text`
WHERE `CreatureID`=39712 AND `GroupID`=1;

INSERT IGNORE INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`)
SELECT
    9457, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`,
    'Horde Defender / Regthar Deathgate SmartAI validation mirror'
FROM `creature_text`
WHERE `CreatureID`=3389 AND `GroupID`=1;

INSERT IGNORE INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`)
SELECT
    16514, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`,
    'Botanist Taerix / Apprentice Tedon SmartAI validation mirror'
FROM `creature_text`
WHERE `CreatureID`=20227 AND `GroupID` IN (1,2);

INSERT IGNORE INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`)
SELECT
    17253, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`,
    'Defile Uthers Tomb Trigger / Ghost of Uther SmartAI validation mirror'
FROM `creature_text`
WHERE `CreatureID`=17233 AND `GroupID` BETWEEN 4 AND 7;

INSERT IGNORE INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`)
SELECT
    24786, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`,
    'Reef Bull / Reef Cow SmartAI validation mirror'
FROM `creature_text`
WHERE `CreatureID`=24797 AND `GroupID`=0;

INSERT IGNORE INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`)
SELECT
    25307, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`,
    'Recruitment Officer Blythe / Civilian Recruit SmartAI validation mirror'
FROM `creature_text`
WHERE `CreatureID`=25317 AND `GroupID`=0;

INSERT IGNORE INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`)
SELECT
    35231, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`,
    'Crowleys Horse / Lord Darius Crowley SmartAI validation mirror'
FROM `creature_text`
WHERE `CreatureID`=35230 AND `GroupID` IN (1,2);
