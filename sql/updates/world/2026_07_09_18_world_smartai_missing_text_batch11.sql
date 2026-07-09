-- Verified SmartAI missing creature_text fixes, batch 11.
-- Uses local npc_text/broadcast_text rows matching the relevant gossip or quest rescue flow.

INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(55488, 0, 0, 'Lost. Stolen! This is a terrible blow. Terrible!', 12, 0, 100, 0, 0, 0, 0, 0, 0, 'Corastrasza - A Hidden Message gossip')
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
(69267, 0, 0, 'Thank you, friend. You have rescued me from a terrible fate.', 12, 0, 8, 0, 0, 0, 0, 71531, 0, 'Silver Covenant Scout - rescue 1'),
(69267, 0, 1, 'Did the Silver Covenant send you? Thank you for the well-timed rescue.', 12, 0, 8, 0, 0, 0, 0, 71514, 0, 'Silver Covenant Scout - rescue 2'),
(69267, 0, 2, 'Thank you. I can find my way back to camp from here.', 12, 0, 8, 0, 0, 0, 0, 71527, 0, 'Silver Covenant Scout - rescue 3'),
(69267, 0, 3, 'Thank you, champion. Please, free the others as well!', 12, 0, 8, 0, 0, 0, 0, 71528, 0, 'Silver Covenant Scout - rescue 4'),
(69267, 0, 4, 'How could the mogu be capable of such atrocity? Thank goodness you arrived when you did.', 12, 0, 8, 0, 0, 0, 0, 71529, 0, 'Silver Covenant Scout - rescue 5'),
(69267, 0, 5, 'You have my eternal gratitude, hero.', 12, 0, 8, 0, 0, 0, 0, 71530, 0, 'Silver Covenant Scout - rescue 6'),
(69267, 0, 6, 'You have saved my life, champion. For that, I am in your debt.', 12, 0, 8, 0, 0, 0, 0, 71532, 0, 'Silver Covenant Scout - rescue 7'),
(69267, 0, 7, 'I knew the Silver Covenant would not desert me. Thank you, champion.', 12, 0, 8, 0, 0, 0, 0, 71515, 0, 'Silver Covenant Scout - rescue 8'),
(69267, 0, 8, 'I should tear you apart, Horde scum! I will restrain myself this once.', 12, 0, 7, 0, 0, 0, 0, 71524, 0, 'Silver Covenant Scout - cross-faction rescue 1'),
(69267, 0, 9, 'I will stay my hand this time, Horde hero. Let it not be said that the Silver Covenant does not show gratitude.', 12, 0, 7, 0, 0, 0, 0, 71523, 0, 'Silver Covenant Scout - cross-faction rescue 2'),
(69267, 0, 10, 'If you had not just rescued me from certain death, I would kill you where you stand. Next time we meet, I will not hold back.', 12, 0, 7, 0, 0, 0, 0, 71525, 0, 'Silver Covenant Scout - cross-faction rescue 3'),
(69267, 0, 11, 'Although we are enemies, I will thank you. Just this once.', 12, 0, 7, 0, 0, 0, 0, 71526, 0, 'Silver Covenant Scout - cross-faction rescue 4'),
(69267, 0, 12, 'Thank you, Horde hero, but next time we meet, I will show no mercy.', 12, 0, 7, 0, 0, 0, 0, 71522, 0, 'Silver Covenant Scout - cross-faction rescue 5')
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
(69305, 0, 0, 'Thank you, friend. You have rescued me from a terrible fate.', 12, 0, 8, 0, 0, 0, 0, 71507, 0, 'Sunreaver Scout - rescue 1'),
(69305, 0, 1, 'Did the Sunreavers send you? Thank you for the well-timed rescue.', 12, 0, 8, 0, 0, 0, 0, 71508, 0, 'Sunreaver Scout - rescue 2'),
(69305, 0, 2, 'Thank you. I can find my way back to camp from here.', 12, 0, 8, 0, 0, 0, 0, 71509, 0, 'Sunreaver Scout - rescue 3'),
(69305, 0, 3, 'Thank you, champion. Please, free the others as well!', 12, 0, 8, 0, 0, 0, 0, 71510, 0, 'Sunreaver Scout - rescue 4'),
(69305, 0, 4, 'How could the mogu be capable of such atrocity? Thank goodness you arrived when you did.', 12, 0, 8, 0, 0, 0, 0, 71511, 0, 'Sunreaver Scout - rescue 5'),
(69305, 0, 5, 'You have my eternal gratitude, hero.', 12, 0, 8, 0, 0, 0, 0, 71512, 0, 'Sunreaver Scout - rescue 6'),
(69305, 0, 6, 'You have saved my life, champion. For that, I am in your debt.', 12, 0, 8, 0, 0, 0, 0, 71513, 0, 'Sunreaver Scout - rescue 7'),
(69305, 0, 7, 'I knew the Sunreavers would not desert me. Thank you, champion.', 12, 0, 8, 0, 0, 0, 0, 71516, 0, 'Sunreaver Scout - rescue 8'),
(69305, 0, 8, 'I should tear you apart, Alliance scum! I will restrain myself this once.', 12, 0, 7, 0, 0, 0, 0, 71517, 0, 'Sunreaver Scout - cross-faction rescue 1'),
(69305, 0, 9, 'I will stay my hand this time, Alliance hero. Let it not be said that the Sunreavers do not show gratitude.', 12, 0, 7, 0, 0, 0, 0, 71518, 0, 'Sunreaver Scout - cross-faction rescue 2'),
(69305, 0, 10, 'If you had not just rescued me from certain death, I would kill you where you stand. Next time we meet, I will not hold back.', 12, 0, 7, 0, 0, 0, 0, 71519, 0, 'Sunreaver Scout - cross-faction rescue 3'),
(69305, 0, 11, 'Although we are enemies, I will thank you. Just this once.', 12, 0, 7, 0, 0, 0, 0, 71520, 0, 'Sunreaver Scout - cross-faction rescue 4'),
(69305, 0, 12, 'Thank you, Alliance hero, but next time we meet, I will show no mercy.', 12, 0, 7, 0, 0, 0, 0, 71521, 0, 'Sunreaver Scout - cross-faction rescue 5')
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
