-- Dire Maul: Pusillin
-- Skip the broken chase sequence and spawn Pusillin directly at his final encounter location.

UPDATE `creature` c
JOIN `waypoints` w
  ON w.`entry` = 430620
 AND w.`pointid` = 7
SET
    c.`position_x` = w.`position_x`,
    c.`position_y` = w.`position_y`,
    c.`position_z` = w.`position_z`,
    c.`orientation` = COALESCE(w.`orientation`, c.`orientation`),
    c.`MovementType` = 0,
    c.`currentwaypoint` = 0
WHERE c.`guid` = 51540
  AND c.`id` = 14354;

-- Run Pusillin's existing final encounter script immediately on spawn.
UPDATE `smart_scripts`
SET
    `action_type`   = 80,
    `action_param1` = 1435404,
    `action_param2` = 0,
    `action_param3` = 0,
    `target_type`   = 1
WHERE `entryorguid` = 14354
  AND `source_type` = 0
  AND `id` = 0;
