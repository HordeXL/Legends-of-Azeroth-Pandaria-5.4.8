-- Glintrok Scout (64243) announces that a saurok escapes with treasure.
--
-- The local origin/uwow-creature_text branch supplies the exact creature_text
-- ownership and BroadcastTextId. The English Build-18414 text is restored from
-- broadcast_text 64421 rather than translated or invented locally.

INSERT INTO `creature_text`
(
    `CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`,
    `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`,
    `BroadcastTextId`, `TextRange`, `comment`
)
SELECT
    64243, 0, 0,
    'A Saurok runs down a hidden set of stairs with some of the treasure!',
    41, 0, 100, 0, 0, 0, 0, 64421, 0,
    'Glintrok Scout - treasure escape emote'
FROM DUAL
WHERE EXISTS
(
    SELECT 1
    FROM `broadcast_text`
    WHERE `ID` = 64421
      AND `Text` = 'A Saurok runs down a hidden set of stairs with some of the treasure!'
)
AND NOT EXISTS
(
    SELECT 1
    FROM `creature_text`
    WHERE `CreatureID` = 64243
      AND `GroupID` = 0
      AND `ID` = 0
);
