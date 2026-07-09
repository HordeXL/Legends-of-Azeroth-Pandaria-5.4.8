-- Verified SmartAI missing creature_text fixes, batch 9.
-- Uses local broadcast_text rows matching known MoP NPC quotes.

INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(59296, 0, 0, 'Grookie wikket!', 12, 0, 20, 0, 0, 0, 0, 58274, 0, 'Lazy Hozen - motivated 1'),
(59296, 0, 1, 'Hozen whakkin'' stinky wikket!', 12, 0, 20, 0, 0, 0, 0, 58273, 0, 'Lazy Hozen - motivated 2'),
(59296, 0, 2, 'Ookin'' dooker!', 12, 0, 20, 0, 0, 0, 0, 58275, 0, 'Lazy Hozen - motivated 3'),
(59296, 0, 3, 'Wikket grookin stinky slickies!', 12, 0, 20, 0, 0, 0, 0, 58272, 0, 'Lazy Hozen - motivated 4'),
(59296, 0, 4, 'Wikkets is furry food!', 12, 0, 20, 0, 0, 0, 0, 58271, 0, 'Lazy Hozen - motivated 5')
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
(59392, 0, 0, 'It''s about time we got another shipment. I heard they were having trouble at the mines, but our work cannot wait.', 12, 0, 100, 0, 0, 0, 0, 58451, 0, 'Kitemaster Shoku - quest gossip')
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
