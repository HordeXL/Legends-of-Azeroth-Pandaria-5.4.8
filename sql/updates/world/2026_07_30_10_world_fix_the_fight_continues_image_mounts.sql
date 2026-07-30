-- Restore the three missing mounts in the RP event for quest 26208,
-- The Fight Continues, without replacing this world's existing event.
--
-- Source:
--   ProjectSkyfire/SkyFire_548 commit
--   ca09b61002f629780c570c37b3bd7c6235e236fd
--
-- The preceding SkyFire event commit uses a different, less complete SmartAI
-- layout than the active event in this world. Only its later mount correction
-- is imported here, using free ids after the existing active rows.

CREATE TABLE IF NOT EXISTS
    `_backup_smart_scripts_fight_continues_mounts_20260730`
LIKE `smart_scripts`;

INSERT INTO `_backup_smart_scripts_fight_continues_mounts_20260730`
SELECT `smart`.*
FROM `smart_scripts` AS `smart`
WHERE `smart`.`source_type` = 0
  AND
    (
        (`smart`.`entryorguid` = 42419 AND `smart`.`id` BETWEEN 0 AND 12)
        OR
        (`smart`.`entryorguid` IN (42420, 42422)
         AND `smart`.`id` IN (0, 1))
    )
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_smart_scripts_fight_continues_mounts_20260730` AS `backup`
       WHERE `backup`.`entryorguid` = `smart`.`entryorguid`
         AND `backup`.`source_type` = `smart`.`source_type`
         AND `backup`.`id` = `smart`.`id`
         AND `backup`.`link` = `smart`.`link`);

START TRANSACTION;

SET @fight_continues_mount_backup_ok :=
(
    SELECT COUNT(*) = 17
       AND SUM(`entryorguid` = 42419
               AND `source_type` = 0
               AND `id` BETWEEN 0 AND 12) = 13
       AND SUM(`entryorguid` = 42420
               AND `source_type` = 0
               AND `id` IN (0, 1)) = 2
       AND SUM(`entryorguid` = 42422
               AND `source_type` = 0
               AND `id` IN (0, 1)) = 2
    FROM `_backup_smart_scripts_fight_continues_mounts_20260730`
);

SET @fight_continues_mount_base_ok :=
(
    SELECT COUNT(*) = 17
       AND SUM(`entryorguid` = 42419
               AND `source_type` = 0
               AND `id` BETWEEN 0 AND 12) = 13
       AND SUM(`entryorguid` = 42420
               AND `source_type` = 0
               AND `id` IN (0, 1)) = 2
       AND SUM(`entryorguid` = 42422
               AND `source_type` = 0
               AND `id` IN (0, 1)) = 2
    FROM `smart_scripts`
    WHERE
        (`entryorguid` = 42419
         AND NOT (`source_type` = 0 AND `id` = 13 AND `link` = 0))
        OR
        (`entryorguid` IN (42420, 42422)
         AND NOT (`source_type` = 0 AND `id` = 2 AND `link` = 0))
);

SET @fight_continues_mount_templates_ok :=
(
    SELECT COUNT(*) = 3
       AND SUM(`AIName` = 'SmartAI') = 3
       AND SUM(COALESCE(`ScriptName`, '') = '') = 3
    FROM `creature_template`
    WHERE `entry` IN (42419, 42420, 42422)
);

SET @fight_continues_mount_slots_ok :=
(
    SELECT COUNT(*) = 0
    FROM `smart_scripts`
    WHERE
        (`entryorguid` = 42419
         AND `source_type` = 0 AND `id` = 13 AND `link` = 0
         AND NOT (`event_type` = 11
                  AND `action_type` = 43
                  AND `action_param1` = 46684
                  AND `target_type` = 1))
        OR
        (`entryorguid` IN (42420, 42422)
         AND `source_type` = 0 AND `id` = 2 AND `link` = 0
         AND NOT (`event_type` = 11
                  AND `action_type` = 43
                  AND `action_param1` = 12363
                  AND `target_type` = 1))
);

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`,
     `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`,
     `event_param5`, `action_type`, `action_param1`, `action_param2`,
     `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`,
     `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`,
     `comment`)
SELECT
    42419, 0, 13, 0,
    11, 0, 100, 0,
    0, 0, 0, 0,
    0, 43, 46684, 0,
    0, 0, 0, 0,
    1, 0, 0, 0,
    0, 0, 0, 0, 0,
    'Image of High Tinker Mekkatorque - On Respawn - Mount Up'
FROM DUAL
WHERE @fight_continues_mount_backup_ok = 1
  AND @fight_continues_mount_base_ok = 1
  AND @fight_continues_mount_templates_ok = 1
  AND @fight_continues_mount_slots_ok = 1
  AND NOT EXISTS
      (SELECT 1
       FROM `smart_scripts`
       WHERE `entryorguid` = 42419
         AND `source_type` = 0 AND `id` = 13 AND `link` = 0);

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`,
     `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`,
     `event_param5`, `action_type`, `action_param1`, `action_param2`,
     `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`,
     `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`,
     `comment`)
SELECT
    42420, 0, 2, 0,
    11, 0, 100, 0,
    0, 0, 0, 0,
    0, 43, 12363, 0,
    0, 0, 0, 0,
    1, 0, 0, 0,
    0, 0, 0, 0, 0,
    'Image of "Doc" Cogspin - On Respawn - Mount Up'
FROM DUAL
WHERE @fight_continues_mount_backup_ok = 1
  AND @fight_continues_mount_base_ok = 1
  AND @fight_continues_mount_templates_ok = 1
  AND @fight_continues_mount_slots_ok = 1
  AND NOT EXISTS
      (SELECT 1
       FROM `smart_scripts`
       WHERE `entryorguid` = 42420
         AND `source_type` = 0 AND `id` = 2 AND `link` = 0);

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`,
     `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`,
     `event_param5`, `action_type`, `action_param1`, `action_param2`,
     `action_param3`, `action_param4`, `action_param5`, `action_param6`,
     `target_type`, `target_param1`, `target_param2`, `target_param3`,
     `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`,
     `comment`)
SELECT
    42422, 0, 2, 0,
    11, 0, 100, 0,
    0, 0, 0, 0,
    0, 43, 12363, 0,
    0, 0, 0, 0,
    1, 0, 0, 0,
    0, 0, 0, 0, 0,
    'Image of Hinkles Fastblast - On Respawn - Mount Up'
FROM DUAL
WHERE @fight_continues_mount_backup_ok = 1
  AND @fight_continues_mount_base_ok = 1
  AND @fight_continues_mount_templates_ok = 1
  AND @fight_continues_mount_slots_ok = 1
  AND NOT EXISTS
      (SELECT 1
       FROM `smart_scripts`
       WHERE `entryorguid` = 42422
         AND `source_type` = 0 AND `id` = 2 AND `link` = 0);

COMMIT;
