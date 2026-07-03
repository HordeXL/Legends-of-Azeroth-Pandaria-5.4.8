-- Fix startup errors from creatures configured for missing waypoint paths.
UPDATE `creature`
SET `MovementType` = 0
WHERE `guid` IN (
  4974, 65763, 67443, 67447, 68292, 72498, 74230, 74231, 75734,
  77840, 78337, 80927, 126119, 303619, 303637, 354560
)
  AND `MovementType` = 2;

UPDATE `creature_addon`
SET `path_id` = 0
WHERE `guid` IN (
  4974, 65763, 67443, 67447, 68292, 72498, 74230, 74231, 75734,
  77840, 78337, 80927, 126119, 303619, 303637, 354560
)
  AND `path_id` IN (
  4974, 65763, 67443, 67447, 68292, 72498, 74230, 74231, 75734,
  77840, 78337, 80927, 126119, 303619, 303637, 354560
);

-- Remove invalid Echo Isle Animal spawns with corrupt Z coordinates.
DELETE FROM `creature_addon` WHERE `guid` IN (505704, 511897);
DELETE FROM `creature` WHERE `guid` IN (505704, 511897)
  AND `id` = 40217
  AND `position_z` < -100000;

-- Remove wild battle pet source spawns that produce invalid runtime Z coordinates.
DELETE FROM `creature_addon` WHERE `guid` IN (
  237571, 240095, 240186, 240214, 240261, 240384,
  527565, 527567, 527568, 527577, 527582
);

DELETE FROM `creature` WHERE `guid` IN (
  237571, 240095, 240186, 240214, 240261, 240384,
  527565, 527567, 527568, 527577, 527582
)
  AND `id` IN (49842, 63980);

-- Let this outdoor SmartAI event load instead of being filtered by instance difficulty flags.
UPDATE `smart_scripts`
SET `event_flags` = `event_flags` & 4294967293
WHERE `entryorguid` = 5649
  AND `source_type` = 0
  AND `id` = 0
  AND (`event_flags` & 2) <> 0;
