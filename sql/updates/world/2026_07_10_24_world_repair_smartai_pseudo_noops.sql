-- Repair earlier pseudo no-ops that used Action 22 (SET_EVENT_PHASE).
-- Preserve the required chain behavior and remove only proven redundant or
-- unreachable steps. Original rows were verified against the 2024-07-22 dump.

-- Blackrock Soldier / Firegut Flamespeaker:
-- spell 89568 grants credit 48195. Link the spell cast directly to the
-- existing dialogue step, bypassing the redundant explicit credit action.
UPDATE `smart_scripts` AS `cast_step`
JOIN `smart_scripts` AS `pseudo_noop`
  ON `pseudo_noop`.`entryorguid` = `cast_step`.`entryorguid`
 AND `pseudo_noop`.`source_type` = 0
 AND `pseudo_noop`.`id` = 1
 AND `pseudo_noop`.`event_type` = 61
 AND `pseudo_noop`.`link` = 2
 AND `pseudo_noop`.`action_type` = 22
 AND `pseudo_noop`.`action_param1` = 0
 AND `pseudo_noop`.`action_param6` = 48195
JOIN `smart_scripts` AS `talk_step`
  ON `talk_step`.`entryorguid` = `cast_step`.`entryorguid`
 AND `talk_step`.`source_type` = 0
 AND `talk_step`.`id` = 2
 AND `talk_step`.`event_type` = 61
 AND `talk_step`.`action_type` = 1
 AND `talk_step`.`action_param1` = 0
SET `cast_step`.`link` = 2
WHERE `cast_step`.`entryorguid` IN (48119, 48121)
  AND `cast_step`.`source_type` = 0
  AND `cast_step`.`id` = 0
  AND `cast_step`.`link` = 1
  AND `cast_step`.`event_type` = 8
  AND `cast_step`.`action_type` = 11
  AND `cast_step`.`action_param1` = 89568;

DELETE `pseudo_noop`
FROM `smart_scripts` AS `pseudo_noop`
JOIN `smart_scripts` AS `cast_step`
  ON `cast_step`.`entryorguid` = `pseudo_noop`.`entryorguid`
 AND `cast_step`.`source_type` = 0
 AND `cast_step`.`id` = 0
 AND `cast_step`.`link` = 2
 AND `cast_step`.`event_type` = 8
 AND `cast_step`.`action_type` = 11
 AND `cast_step`.`action_param1` = 89568
JOIN `smart_scripts` AS `talk_step`
  ON `talk_step`.`entryorguid` = `pseudo_noop`.`entryorguid`
 AND `talk_step`.`source_type` = 0
 AND `talk_step`.`id` = 2
 AND `talk_step`.`event_type` = 61
 AND `talk_step`.`action_type` = 1
 AND `talk_step`.`action_param1` = 0
WHERE `pseudo_noop`.`entryorguid` IN (48119, 48121)
  AND `pseudo_noop`.`source_type` = 0
  AND `pseudo_noop`.`id` = 1
  AND `pseudo_noop`.`event_type` = 61
  AND `pseudo_noop`.`link` = 2
  AND `pseudo_noop`.`action_type` = 22
  AND `pseudo_noop`.`action_param1` = 0
  AND `pseudo_noop`.`action_param6` = 48195;

-- Master Shang Xi:
-- spell 109335 already summons creature 57874. End the link chain after the
-- spell cast and remove the redundant explicit summon step.
UPDATE `smart_scripts` AS `cast_step`
JOIN `smart_scripts` AS `pseudo_noop`
  ON `pseudo_noop`.`entryorguid` = 56686
 AND `pseudo_noop`.`source_type` = 0
 AND `pseudo_noop`.`id` = 8
 AND `pseudo_noop`.`event_type` = 61
 AND `pseudo_noop`.`link` = 0
 AND `pseudo_noop`.`action_type` = 22
 AND `pseudo_noop`.`action_param1` = 0
 AND `pseudo_noop`.`action_param6` = 57874
SET `cast_step`.`link` = 0
WHERE `cast_step`.`entryorguid` = 56686
  AND `cast_step`.`source_type` = 0
  AND `cast_step`.`id` = 7
  AND `cast_step`.`event_type` = 61
  AND `cast_step`.`link` = 8
  AND `cast_step`.`action_type` = 11
  AND `cast_step`.`action_param1` = 109335;

DELETE `pseudo_noop`
FROM `smart_scripts` AS `pseudo_noop`
JOIN `smart_scripts` AS `cast_step`
  ON `cast_step`.`entryorguid` = 56686
 AND `cast_step`.`source_type` = 0
 AND `cast_step`.`id` = 7
 AND `cast_step`.`event_type` = 61
 AND `cast_step`.`link` = 0
 AND `cast_step`.`action_type` = 11
 AND `cast_step`.`action_param1` = 109335
WHERE `pseudo_noop`.`entryorguid` = 56686
  AND `pseudo_noop`.`source_type` = 0
  AND `pseudo_noop`.`id` = 8
  AND `pseudo_noop`.`event_type` = 61
  AND `pseudo_noop`.`link` = 0
  AND `pseudo_noop`.`action_type` = 22
  AND `pseudo_noop`.`action_param1` = 0
  AND `pseudo_noop`.`action_param6` = 57874;

-- Ramkahen Prisoner:
-- this obsolete text-group-3 waypoint step was made unreachable by the
-- verified three-line flow. Remove it only while no row links to id 12.
DELETE `obsolete`
FROM `smart_scripts` AS `obsolete`
LEFT JOIN `smart_scripts` AS `incoming`
  ON `incoming`.`entryorguid` = `obsolete`.`entryorguid`
 AND `incoming`.`source_type` = `obsolete`.`source_type`
 AND `incoming`.`link` = `obsolete`.`id`
WHERE `obsolete`.`entryorguid` = 46425
  AND `obsolete`.`source_type` = 0
  AND `obsolete`.`id` = 12
  AND `obsolete`.`event_type` = 61
  AND `obsolete`.`link` = 0
  AND `obsolete`.`action_type` = 22
  AND `obsolete`.`action_param1` = 0
  AND `obsolete`.`action_param6` = 46425
  AND `incoming`.`entryorguid` IS NULL;
