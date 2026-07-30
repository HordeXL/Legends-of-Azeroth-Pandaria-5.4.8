-- Exact rollback for
-- 2026_07_30_10_world_fix_the_fight_continues_image_mounts.sql.
--
-- The migration adds three previously absent SmartAI rows and does not modify
-- any original row. Remove only those three exact rows while the complete
-- 17-row pre-change SmartAI backup remains available.

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

DELETE FROM `smart_scripts`
WHERE @fight_continues_mount_backup_ok = 1
  AND
    (
        (`entryorguid` = 42419
         AND `source_type` = 0 AND `id` = 13 AND `link` = 0
         AND `event_type` = 11
         AND `event_phase_mask` = 0
         AND `event_chance` = 100
         AND `event_flags` = 0
         AND `action_type` = 43
         AND `action_param1` = 46684
         AND `target_type` = 1
         AND `comment` =
             'Image of High Tinker Mekkatorque - On Respawn - Mount Up')
        OR
        (`entryorguid` = 42420
         AND `source_type` = 0 AND `id` = 2 AND `link` = 0
         AND `event_type` = 11
         AND `event_phase_mask` = 0
         AND `event_chance` = 100
         AND `event_flags` = 0
         AND `action_type` = 43
         AND `action_param1` = 12363
         AND `target_type` = 1
         AND `comment` =
             'Image of "Doc" Cogspin - On Respawn - Mount Up')
        OR
        (`entryorguid` = 42422
         AND `source_type` = 0 AND `id` = 2 AND `link` = 0
         AND `event_type` = 11
         AND `event_phase_mask` = 0
         AND `event_chance` = 100
         AND `event_flags` = 0
         AND `action_type` = 43
         AND `action_param1` = 12363
         AND `target_type` = 1
         AND `comment` =
             'Image of Hinkles Fastblast - On Respawn - Mount Up')
    );

COMMIT;
