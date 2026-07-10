-- Verified SmartAI missing creature_text fixes.
-- Scope is intentionally small: only rows with a trusted local broadcast_text
-- or a clear SmartAI group mismatch are changed.

-- Auctioneer Fitch / Hired Courier quest "Fencing the Goods":
-- existing DB had only the third line stored as GroupID 0. Restore the 3-line sequence.
UPDATE `creature_text`
SET `Text` = 'Look, in my business, discretion is important. I shouldn''t be talking about this at all.',
    `Type` = 12,
    `Language` = 0,
    `Probability` = 100,
    `Emote` = 0,
    `Duration` = 0,
    `Sound` = 0,
    `SoundType` = 0,
    `BroadcastTextId` = 52638,
    `TextRange` = 0,
    `comment` = 'Auctioneer Fitch - Fencing the Goods 1'
WHERE `CreatureID` = 8719 AND `GroupID` = 0 AND `ID` = 0;

INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(8719, 1, 0, 'The person you described was just here and he tried to persuade me to list a crateful of arcane objects.', 12, 0, 100, 0, 0, 0, 0, 52639, 0, 'Auctioneer Fitch - Fencing the Goods 2'),
(8719, 2, 0, 'Naturally, I told him that we don''t deal in stolen goods. This is the Stormwind auction house, not some smoke-filled, back alley swapmeet!', 12, 0, 100, 0, 0, 0, 0, 52640, 0, 'Auctioneer Fitch - Fencing the Goods 3')
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

-- Flik already has all random OOC sayings in GroupID 0, IDs 0-3.
UPDATE `smart_scripts`
SET `action_param1` = 0,
    `comment` = CONCAT(`comment`, ' - Use existing random creature_text group 0')
WHERE `entryorguid` = 14860
  AND `source_type` = 0
  AND `id` = 1
  AND `action_type` = 1
  AND `action_param1` = 1;

-- Arzeth the Merciless: spell-hit link line after Fury of the Dreghood Elders.
INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(19354, 1, 0, 'That Broken worm gave you that staff, didn''t he?  Did he also tell you he''s the one that sold out his tribe?  No matter, you will both pay for this!', 14, 0, 100, 0, 0, 0, 0, 18349, 0, 'Arzeth the Merciless - spellhit response')
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

-- Brewfest Gordok Brew Barker already has all random yell lines in GroupID 0, IDs 0-2.
UPDATE `smart_scripts`
SET `action_param1` = 0,
    `comment` = CONCAT(`comment`, ' - Use existing random creature_text group 0')
WHERE `entryorguid` = -84635
  AND `source_type` = 0
  AND `id` = 4
  AND `action_type` = 1
  AND `action_param1` = 1;

-- Caimas the Pit Master: local broadcast_text has the missing aggro/combat line.
INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
(46276, 4, 0, 'That''s it? Ya gotta have more than that!', 14, 0, 100, 0, 0, 0, 0, 46639, 0, 'Caimas the Pit Master - aggro')
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

-- Ramkahen Prisoner / Neferset Prison:
-- trusted quest flow has only lines 0, 1, and 2. Start waypoint after line 2
-- instead of requiring a non-existent line 3.
UPDATE `smart_scripts`
SET `action_type` = 53,
    `action_param1` = 1,
    `action_param2` = 46425,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `target_type` = 1,
    `comment` = 'Ramkahen Prisoner - On Text Over 2 - Waypoint Start'
WHERE `entryorguid` = 46425
  AND `source_type` = 0
  AND `id` = 11
  AND `event_type` = 52
  AND `event_param1` = 2
  AND `action_type` = 1
  AND `action_param1` = 3;

UPDATE `smart_scripts`
SET `event_type` = 61,
    `action_type` = 22,
    `action_param1` = 0,
    `action_param6` = 46425,
    `comment` = CONCAT(`comment`, ' - Disabled; waypoint now starts after text group 2')
WHERE `entryorguid` = 46425
  AND `source_type` = 0
  AND `id` = 12
  AND `event_type` = 52
  AND `event_param1` = 3
  AND `action_type` = 53;
