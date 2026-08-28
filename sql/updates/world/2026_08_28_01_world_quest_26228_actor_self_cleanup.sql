-- Quest 26228 "Livin' the Life": each temporary scene actor removes itself
-- when the house grants quest credit. This avoids leaving Glubtok behind when
-- the house cannot resolve him for its passenger-removed cleanup action.
DELETE FROM `smart_scripts`
WHERE `source_type` = 9
  AND ((`entryorguid` = 4249200 AND `id` = 5)
    OR (`entryorguid` = 4251500 AND `id` = 9));
INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`,
     `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`,
     `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (4249200, 9, 5, 0, 0, 0, 100, 0, 13900, 13900, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Glubtok - Despawn when scene completes'),
    (4251500, 9, 9, 0, 0, 0, 100, 0,  2500,  2500, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Shadowy Figure - Despawn when scene completes');
