-- Vanessa Sellers (32514) has the Build-18414 aura 60913
-- "[DND] Dalaran - Shop Keeper Greeting", but no group-0 creature_text.
-- Use the same seven generic Dalaran shopkeeper broadcasts as the other
-- aura-60913 vendors, including Jessica Sellers (33027).  This prevents the
-- runtime CreatureTextMgr missing-text diagnostic without inventing dialogue.
DELETE FROM `creature_text`
WHERE `CreatureID` = 32514
  AND `GroupID` = 0;

INSERT INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`,
 `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`,
 `comment`)
VALUES
(32514, 0, 0, 'Let me know if you need help finding anything, $c.', 12, 0, 100, 3, 0, 0, 0, 32810, 0, 'Vanessa Sellers - Dalaran shopkeeper greeting'),
(32514, 0, 1, 'Greetings, $c.',                                      12, 0, 100, 3, 0, 0, 0, 32808, 0, 'Vanessa Sellers - Dalaran shopkeeper greeting'),
(32514, 0, 2, 'Welcome. May I help you find something?',              12, 0, 100, 3, 0, 0, 0, 32811, 0, 'Vanessa Sellers - Dalaran shopkeeper greeting'),
(32514, 0, 3, 'Greetings! Please have a look around.',                12, 0, 100, 3, 0, 0, 0, 32809, 0, 'Vanessa Sellers - Dalaran shopkeeper greeting'),
(32514, 0, 4, 'Welcome.',                                             12, 0, 100, 3, 0, 0, 0, 32936, 0, 'Vanessa Sellers - Dalaran shopkeeper greeting'),
(32514, 0, 5, 'Welcome!',                                             12, 0, 100, 0, 0, 0, 0, 32807, 0, 'Vanessa Sellers - Dalaran shopkeeper greeting'),
(32514, 0, 6, 'Greetings.',                                           12, 0, 100, 0, 0, 0, 0, 32935, 0, 'Vanessa Sellers - Dalaran shopkeeper greeting');
