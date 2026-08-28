-- Quest 26228 "Livin' the Life": let each summoned actor own and run its
-- dialogue timeline. Lou's house could complete its own timeline and credit
-- the player while failing to resolve the other temporary summons as TALK
-- targets, leaving the entire scene silent.

-- Start a combat-safe timed list on each actor as soon as it is created.
DELETE FROM `smart_scripts`
WHERE `source_type` = 0
  AND ((`entryorguid` = 42492 AND `id` = 1)
    OR (`entryorguid` = 42515 AND `id` = 2));
INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`,
     `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`,
     `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (42492, 0, 1, 0, 63, 0, 100, 0, 0, 0, 0, 0, 80, 4249200, 0, 2, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Glubtok - Just Created - Start own dialogue timeline'),
    (42515, 0, 2, 0, 63, 0, 100, 0, 0, 0, 0, 0, 80, 4251500, 0, 2, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Shadowy Figure - Just Created - Start own dialogue timeline');

-- The house now owns only the final credit/vehicle-exit timer.
DELETE FROM `smart_scripts`
WHERE `source_type` = 9 AND `entryorguid` IN (4250000, 4249200, 4251500);
INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`,
     `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`,
     `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (4250000, 9, 0, 0, 0, 0, 100, 0, 76200, 76200, 0, 0, 11, 79275, 2, 0, 0, 0, 0, 23, 0, 0, 0, 0, 0, 0, 0, 'Jangolode scene - Credit house owner and exit vehicle'),

    (4249200, 9, 0, 0, 0, 0, 100, 0,  9300,  9300, 0, 0,   1,   0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Glubtok - Line 0'),
    (4249200, 9, 1, 0, 0, 0, 100, 0, 14500, 14500, 0, 0,   1,   1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Glubtok - Line 1'),
    (4249200, 9, 2, 0, 0, 0, 100, 0, 20000, 20000, 0, 0,   1,   2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Glubtok - Line 2'),
    (4249200, 9, 3, 0, 0, 0, 100, 0, 10500, 10500, 0, 0,   1,   3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Glubtok - Line 3'),
    (4249200, 9, 4, 0, 0, 0, 100, 0,  8000,  8000, 0, 0,   1,   4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Glubtok - Line 4'),

    (4251500, 9, 0, 0, 0, 0, 100, 0, 15800, 15800, 0, 0,   1,   0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Shadowy Figure - Line 0'),
    (4251500, 9, 1, 0, 0, 0, 100, 0,     1,     1, 0, 0, 128, 610, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Shadowy Figure - Anim 610'),
    (4251500, 9, 2, 0, 0, 0, 100, 0, 11999, 11999, 0, 0,   1,   1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Shadowy Figure - Line 1'),
    (4251500, 9, 3, 0, 0, 0, 100, 0,  1000,  1000, 0, 0, 128, 593, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Shadowy Figure - Anim 593'),
    (4251500, 9, 4, 0, 0, 0, 100, 0,  8000,  8000, 0, 0,   1,   2, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Shadowy Figure - Line 2'),
    (4251500, 9, 5, 0, 0, 0, 100, 0,  1000,  1000, 0, 0, 128, 606, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Shadowy Figure - Anim 606'),
    (4251500, 9, 6, 0, 0, 0, 100, 0, 10100, 10100, 0, 0,   1,   3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Shadowy Figure - Line 3'),
    (4251500, 9, 7, 0, 0, 0, 100, 0, 17800, 17800, 0, 0,   1,   4, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Shadowy Figure - Line 4'),
    (4251500, 9, 8, 0, 0, 0, 100, 0,  8000,  8000, 0, 0,   1,   5, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Shadowy Figure - Line 5');
