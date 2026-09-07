-- Read-only preflight found both keys absent. Undo only the newly inserted
-- records, preserving any row whose content has subsequently been changed.
DELETE t FROM `creature_text` t
JOIN `broadcast_text` b ON b.`ID` = t.`BroadcastTextId` AND b.`Text` = t.`Text`
WHERE t.`ID` = 0 AND t.`Probability` = 100 AND t.`TextRange` = 0
  AND t.`Language` = b.`LanguageID` AND t.`Sound` = b.`SoundEntriesID`
  AND t.`Emote` = 0 AND t.`Duration` = 0 AND t.`SoundType` = 0
  AND ((t.`CreatureID` = 56747 AND t.`GroupID` = 9 AND t.`BroadcastTextId` = 1028
        AND t.`Type` = 12 AND t.`comment` = 'Gu Cloudstrike - phase three')
    OR (t.`CreatureID` = 56754 AND t.`GroupID` = 2 AND t.`BroadcastTextId` = 63567
        AND t.`Type` = 41 AND t.`comment` = 'Azure Serpent - Magnetic Shroud warning'));
