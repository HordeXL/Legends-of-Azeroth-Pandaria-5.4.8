-- Follow-up cleanup for startup warnings.
--
-- Notes:
-- - Adds missing creature_text rows from existing broadcast_text data.
-- - Does not delete NPC spawns.
-- - Champion of the Black Flame spawns 300017 and 300020 have MovementType=2
--   but no waypoint_data/path_id. Keep the spawns and make them stationary.

DELETE FROM `creature_text`
WHERE `CreatureID` IN (32710, 35498)
  AND `GroupID` = 0
  AND `ID` = 0;

INSERT INTO `creature_text`
    (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`, `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`, `BroadcastTextId`, `TextRange`, `comment`)
VALUES
    (32710, 0, 0, 'I hope you fellows don''t mind if we crash this party.  I brought some old friends with me!', 12, 0, 100, 0, 0, 0, 0, 32710, 0, 'Garl Grimgrizzle'),
    (35498, 0, 0, 'Let''s round up as many of them as we can.  Every worgen chasing us is one less worgen chasing the survivors!', 12, 0, 100, 0, 0, 19696, 0, 35498, 0, 'Horace Hunderland');

UPDATE `creature`
SET `MovementType` = 0
WHERE `guid` IN (300017, 300020)
  AND `id` = 73171
  AND `MovementType` = 2;
