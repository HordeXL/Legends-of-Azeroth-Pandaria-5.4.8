-- Verified SmartAI missing creature_text fixes, batch 10.
-- Uses local broadcast_text rows matching known MoP NPC quotes.

INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(54615, 2, 0, 'Over here, $n! Your gyrocopter''s ready to go!', 12, 0, 100, 0, 0, 0, 0, 68502, 0, 'Nodd Codejack - gyrocopter ready')
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

INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(54944, 1, 0, 'Good fight.', 12, 0, 34, 0, 0, 0, 0, 53244, 0, 'Tian Pupil - duel complete 1'),
(54944, 1, 1, 'Good fight. I''ll get you next time.', 12, 0, 33, 0, 0, 0, 0, 53240, 0, 'Tian Pupil - duel complete 2'),
(54944, 1, 2, 'I don''t think I ever stood a chance. See you around, then!', 12, 0, 33, 0, 0, 0, 0, 53246, 0, 'Tian Pupil - duel complete 3')
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

INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(66693, 0, 0, 'Work harder you lazy mongrels, or I''ll roast you alive!', 14, 0, 20, 0, 0, 0, 0, 67810, 0, 'Zandalari Overlord - aggro 1'),
(66693, 0, 1, 'Break any of these supplies, and I''ll break your skull!', 14, 0, 20, 0, 0, 0, 0, 67811, 0, 'Zandalari Overlord - aggro 2'),
(66693, 0, 2, 'Guard these supplies with your lives, you filthy mutts!', 14, 0, 20, 0, 0, 0, 0, 67812, 0, 'Zandalari Overlord - aggro 3'),
(66693, 0, 3, 'Keep your flea ridden paws out of the food, you mangy beasts!', 14, 0, 20, 0, 0, 0, 0, 67813, 0, 'Zandalari Overlord - aggro 4'),
(66693, 0, 4, 'Watch these mercenaries closely, brothers!', 14, 0, 20, 0, 0, 0, 0, 67814, 0, 'Zandalari Overlord - aggro 5')
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
