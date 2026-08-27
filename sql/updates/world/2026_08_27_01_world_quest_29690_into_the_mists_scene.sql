-- Quest 29690 "Into the Mists": spell 121545 is cast by Nazgrim, but its
-- PLAY_SCENE_ID effect only works when the caster is a player. Preserve the
-- phase spell and play scene 87 directly for the gossip invoker.

UPDATE `smart_scripts`
SET `link` = 2,
    `comment` = 'q29690 - Nazgrim - Linked - Cast 121545 (phase)'
WHERE `entryorguid` = 55054 AND `source_type` = 0 AND `id` = 1
  AND `event_type` = 61 AND `action_type` = 85 AND `action_param1` = 121545;

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 55054 AND `source_type` = 0 AND `id` = 2;

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`,
     `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`,
     `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (55054, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 201, 87, 1, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0,
     'q29690 - Nazgrim - Linked - Play Into the Mists scene 87');
