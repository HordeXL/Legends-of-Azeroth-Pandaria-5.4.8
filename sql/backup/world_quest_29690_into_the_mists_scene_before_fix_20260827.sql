-- Rollback for 2026_08_27_01_world_quest_29690_into_the_mists_scene.sql.

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 55054 AND `source_type` = 0 AND `id` = 2
  AND `event_type` = 61 AND `action_type` = 201 AND `action_param1` = 87;

UPDATE `smart_scripts`
SET `link` = 0,
    `comment` = 'q29690 - Nazgrim - Linked - Cast 121545'
WHERE `entryorguid` = 55054 AND `source_type` = 0 AND `id` = 1
  AND `event_type` = 61 AND `action_type` = 85 AND `action_param1` = 121545;
