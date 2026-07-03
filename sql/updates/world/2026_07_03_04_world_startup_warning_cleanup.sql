-- Tabitha uses the same historical text that is already present for Xarantaur.
DELETE FROM `creature_text` WHERE `CreatureID` = 32752 AND `GroupID` = 0 AND `ID` = 0;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`) VALUES
(32752, 0, 0, 'The wind used its minions to distort the history of this place, changing the stories your people told, destroying the spirits of the honored dead.', 12, 0, 100, 0, 0, 0, 0, 32752, 0, 'Tabitha');

-- Kolkar Stormseer already has SmartAI; this duplicate template install produces a startup warning.
DELETE FROM `smart_scripts`
WHERE `entryorguid` = 9523
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 0
  AND `event_type` = 11
  AND `action_type` = 58;

-- Remove any future bad Tainted Moth spawns if an older SQL import reintroduces them.
DELETE FROM `creature`
WHERE `id` = 62315
  AND `position_z` < -99999;
