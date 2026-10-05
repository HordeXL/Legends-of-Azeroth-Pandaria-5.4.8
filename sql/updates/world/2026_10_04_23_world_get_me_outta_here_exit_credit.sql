-- Quest 25332: Get Me Outta Here!
-- The chained quest giver (39640) is a vehicle accessory.  Despawning the
-- accessory on accept leaves the vehicle alive and permanently removes the
-- quest giver until a world restart, so keep it available for retries and
-- other players.
UPDATE `smart_scripts`
SET `link` = 0,
    `comment` = 'Kristoff Manheim - On Accepted Quest - Cross Cast Shadowed by Kristoff'
WHERE `entryorguid` = 39640
  AND `source_type` = 0
  AND `id` = 0;

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 39640
  AND `source_type` = 0
  AND `id` = 1
  AND `action_type` = 41;

-- Kristoff follows the player rather than a fixed escort path.  The original
-- completion check ran on an invisible exit bunny and could be missed when
-- that spawn's AI was not updating.  Run the distance check on the summoned
-- Kristoff instead; he is guaranteed to update while following the player.
DELETE FROM `smart_scripts`
WHERE (`entryorguid` = -285238 AND `source_type` = 0 AND `id` = 0)
   OR (`entryorguid` = 39797 AND `source_type` = 0 AND `id` IN (12, 13));

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
     `event_chance`, `event_flags`, `event_param1`, `event_param2`,
     `event_param3`, `event_param4`, `event_param5`, `action_type`,
     `action_param1`, `action_param2`, `action_param3`, `action_param4`,
     `action_param5`, `action_param6`, `target_type`, `target_param1`,
     `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`,
     `target_o`, `comment`)
VALUES
    (39797, 0, 12, 0, 75, 0, 100, 0, 285238, 0, 35, 1000, 0, 45,
     0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
     'Kristoff Manheim - within 35 yards of exit marker - Set Data 0 1'),
    (39797, 0, 13, 0, 54, 0, 100, 0, 0, 0, 0, 0, 0, 29,
     0, 0, 0, 0, 0, 0, 23, 0, 0, 0, 0, 0, 0, 0,
     'Kristoff Manheim - On Summoned - immediately follow summoner');
