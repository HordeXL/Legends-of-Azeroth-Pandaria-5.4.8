-- Verified SmartAI missing creature_text fixes, batch 7.
-- Uses local broadcast_text rows and matching SmartAI patterns from similar NPCs.

INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(18938, 0, 0, 'Guards!', 14, 0, 100, 0, 0, 0, 0, 4583, 0, 'Krexcil - Flight Master aggro'),
(45152, 0, 0, 'You''ll pay with your life for interfering with my plans, you miserable scum!', 14, 0, 100, 0, 0, 0, 0, 45301, 0, 'Magus Bisp - Bagging Bisp aggro')
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
