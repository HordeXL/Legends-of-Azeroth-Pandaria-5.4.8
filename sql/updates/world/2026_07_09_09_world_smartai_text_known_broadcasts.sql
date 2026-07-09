-- SmartAI text rows backed by existing broadcast_text and matching local script flow.

INSERT IGNORE INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`)
SELECT
    30474, 2, 0, `Text`, 14, `LanguageID`, 100, `EmotesID`, 0, `SoundEntriesID`, 0, `ID`, 0,
    'North Wind - horn phase'
FROM `broadcast_text`
WHERE `ID`=31183;

INSERT IGNORE INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`)
SELECT
    46425, 2, 0, `Text`, 12, `LanguageID`, 100, `EmotesID`, 0, `SoundEntriesID`, 0, `ID`, 0,
    'Ramkahen Prisoner - warning'
FROM `broadcast_text`
WHERE `ID`=46522;

INSERT IGNORE INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`SoundType`,`BroadcastTextId`,`TextRange`,`comment`)
SELECT
    54924, 1, 0, `Text`, 12, `LanguageID`, 100, `EmotesID`, 0, `SoundEntriesID`, 0, `ID`, 0,
    'Zhi-Zhi - sparring complete'
FROM `broadcast_text`
WHERE `ID`=53204;
