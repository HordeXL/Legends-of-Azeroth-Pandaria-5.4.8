-- Restore existing client broadcast texts used by the Shado-Pan encounter.
-- Do not overwrite customized rows. No invented dialogue or sound IDs.
INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`,
 `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
SELECT 56747, 9, 0, b.`Text`, 12, b.`LanguageID`, 100,
       0, 0, b.`SoundEntriesID`, 0, b.`ID`, 0, 'Gu Cloudstrike - phase three'
FROM `broadcast_text` b
WHERE b.`ID` = 1028 AND b.`Text` = 'Power! Glorious power!'
  AND NOT EXISTS (SELECT 1 FROM `creature_text` t
                  WHERE t.`CreatureID` = 56747 AND t.`GroupID` = 9 AND t.`ID` = 0);

INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`,
 `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
SELECT 56754, 2, 0, b.`Text`, 41, b.`LanguageID`, 100,
       0, 0, b.`SoundEntriesID`, 0, b.`ID`, 0, 'Azure Serpent - Magnetic Shroud warning'
FROM `broadcast_text` b
WHERE b.`ID` = 63567
  AND NOT EXISTS (SELECT 1 FROM `creature_text` t
                  WHERE t.`CreatureID` = 56754 AND t.`GroupID` = 2 AND t.`ID` = 0);
