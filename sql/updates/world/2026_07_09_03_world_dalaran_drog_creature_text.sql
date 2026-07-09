-- Runtime CreatureTextMgr cleanup for additional Dalaran visitor NPC.
-- Non-destructive: do not delete or replace existing creature_text rows.
-- Exact sniffed text was not present in local sources during review.

INSERT IGNORE INTO `creature_text`
(`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(32702, 0, 0, 'Greetings!', 12, 0, 100, 0, 0, 0, 0, 2872, 0, 'Drog Skullbreaker - neutral fallback greeting');
