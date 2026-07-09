-- Verified SmartAI missing creature_text fixes, batch 5.
-- Uses local broadcast_text rows for known NPC quotes.

-- Tinkerer Gizlock, Maraudon.
INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(13601, 0, 0, 'Mine! Mine! Mine!  Gizlock is the ruler of this domain!  You shall never reveal my presence!', 14, 0, 100, 0, 0, 0, 0, 8852, 0, 'Tinkerer Gizlock - aggro')
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

-- Nakk'rakas, Kun-Lai Summit.
INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(60572, 0, 0, 'You can''t stop what has begun!', 14, 0, 100, 0, 0, 0, 0, 61229, 0, 'Nakk''rakas - aggro'),
(60572, 1, 0, 'Da Thunder King will return!', 14, 0, 100, 0, 0, 0, 0, 61232, 0, 'Nakk''rakas - guard killed 1'),
(60572, 2, 0, 'These guardians are just da beginning!', 14, 0, 100, 0, 0, 0, 0, 61230, 0, 'Nakk''rakas - guard killed 2'),
(60572, 3, 0, 'Enough! I''ll handle you myself!', 14, 0, 100, 0, 0, 0, 0, 61269, 0, 'Nakk''rakas - fifth guard killed'),
(60572, 4, 0, 'My death will not stop da storm that is coming! Da Thunder King will rise!', 14, 0, 100, 0, 0, 0, 0, 60775, 0, 'Nakk''rakas - death')
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

-- Dustbelcher Lord, random aggro lines.
INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(2719, 0, 0, 'I''ll crush you!', 12, 0, 50, 0, 0, 0, 0, 1925, 0, 'Dustbelcher Lord - aggro 1'),
(2719, 0, 1, 'Me smash! You die!', 12, 0, 50, 0, 0, 0, 0, 1926, 0, 'Dustbelcher Lord - aggro 2')
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

-- Winterskorn Oracle, random combat lines.
INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(23669, 0, 0, 'My life for Ymiron!', 12, 0, 17, 0, 0, 0, 0, 22702, 0, 'Winterskorn Oracle - combat 1'),
(23669, 0, 1, 'For Ymiron!', 12, 0, 17, 0, 0, 0, 0, 22697, 0, 'Winterskorn Oracle - combat 2'),
(23669, 0, 2, 'There will be no everlasting life for you!', 12, 0, 17, 0, 0, 0, 0, 22822, 0, 'Winterskorn Oracle - combat 3'),
(23669, 0, 3, 'YAAARRRGH!', 12, 0, 17, 0, 0, 0, 0, 22700, 0, 'Winterskorn Oracle - combat 4'),
(23669, 0, 4, 'Look what''s come to play.', 12, 0, 16, 0, 0, 0, 0, 22820, 0, 'Winterskorn Oracle - combat 5'),
(23669, 0, 5, 'I''ll eat your heart!', 12, 0, 16, 0, 0, 0, 0, 30508, 0, 'Winterskorn Oracle - combat 6')
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
