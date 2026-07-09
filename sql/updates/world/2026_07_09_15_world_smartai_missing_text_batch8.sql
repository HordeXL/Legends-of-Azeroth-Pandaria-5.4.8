-- Verified SmartAI missing creature_text fixes, batch 8.
-- These NPCs use the same 15% HP flee + say pattern as existing SmartAI rows.

INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(46134, 0, 0, '%s attempts to run away in fear!', 16, 0, 100, 0, 0, 0, 0, 1150, 0, 'High Commander Kamses - flee emote'),
(46402, 0, 0, '%s attempts to run away in fear!', 16, 0, 100, 0, 0, 0, 0, 1150, 0, 'Ramkahen Citizen - flee emote'),
(48012, 0, 0, '%s attempts to run away in fear!', 16, 0, 100, 0, 0, 0, 0, 1150, 0, 'Sergeant Mehat - flee emote')
ON DUPLICATE KEY UPDATE
`Text` = VALUES(`Text`),
`Type` = VALUES(`Type`),
`Language` = VALUES(`Language`),
`Probability` = VALUES(`Probability`),
`Emote` = VALUES(`Emote`),
`Duration` = VALUES(`Duration`),
`Sound` = VALUES(`Sound`),
`SoundType` = VALUES(`SoundType`),
`BroadcastTextId` = VALUES(`BroadcastTextId`),
`TextRange` = VALUES(`TextRange`),
`comment` = VALUES(`comment`);
