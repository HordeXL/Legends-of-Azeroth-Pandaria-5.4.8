-- Quest 26228 "Livin' the Life": drive the scene directly from Lou's house.
-- The original generic trigger spells use implicit hostile-area targeting, so
-- they reject the non-attackable/immune scene actors and the dialogue stalls.

-- Keep Shadowy Figure's creation/movement rows and Glubtok's positioning row,
-- but remove the now-unused spell-hit relay events.
DELETE FROM `smart_scripts`
WHERE `source_type` = 0
  AND ((`entryorguid` = 42515 AND `id` BETWEEN 2 AND 7)
    OR (`entryorguid` = 42492 AND `id` BETWEEN 1 AND 5));

-- Despawn both actors directly when the passenger leaves the house.
DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = 42500 AND `id` IN (1, 2);
INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`,
     `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`,
     `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (42500, 0, 1, 2, 28, 0, 100, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 19, 42515, 200, 0, 0, 0, 0, 0, 'Lou''s Old House - Passenger Removed - Despawn Shadowy Figure'),
    (42500, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 19, 42492, 200, 0, 0, 0, 0, 0, 'Lou''s Old House - Linked - Despawn Glubtok');

-- Replace the spell-hit relay chain with one combat-safe direct timeline.
DELETE FROM `smart_scripts`
WHERE `source_type` = 9 AND `entryorguid` IN (4250000, 4251500, 4251501, 4249200);
INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
     `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`,
     `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`,
     `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`)
VALUES
    (4250000, 9,  0, 0, 0, 0, 100, 0, 9300, 9300, 0, 0,   1,     0, 0, 0, 0, 0, 0, 19, 42492, 200, 0, 0, 0, 0, 0, 'Jangolode scene - Glubtok line 0'),
    (4250000, 9,  1, 0, 0, 0, 100, 0, 6500, 6500, 0, 0,   1,     0, 0, 0, 0, 0, 0, 19, 42515, 200, 0, 0, 0, 0, 0, 'Jangolode scene - Shadowy Figure line 0'),
    (4250000, 9,  2, 0, 0, 0, 100, 0,    1,    1, 0, 0, 128,   610, 0, 0, 0, 0, 0, 19, 42515, 200, 0, 0, 0, 0, 0, 'Jangolode scene - Shadowy Figure anim 610'),
    (4250000, 9,  3, 0, 0, 0, 100, 0, 7999, 7999, 0, 0,   1,     1, 0, 0, 0, 0, 0, 19, 42492, 200, 0, 0, 0, 0, 0, 'Jangolode scene - Glubtok line 1'),
    (4250000, 9,  4, 0, 0, 0, 100, 0, 4000, 4000, 0, 0,   1,     1, 0, 0, 0, 0, 0, 19, 42515, 200, 0, 0, 0, 0, 0, 'Jangolode scene - Shadowy Figure line 1'),
    (4250000, 9,  5, 0, 0, 0, 100, 0, 1000, 1000, 0, 0, 128,   593, 0, 0, 0, 0, 0, 19, 42515, 200, 0, 0, 0, 0, 0, 'Jangolode scene - Shadowy Figure anim 593'),
    (4250000, 9,  6, 0, 0, 0, 100, 0, 8000, 8000, 0, 0,   1,     2, 0, 0, 0, 0, 0, 19, 42515, 200, 0, 0, 0, 0, 0, 'Jangolode scene - Shadowy Figure line 2'),
    (4250000, 9,  7, 0, 0, 0, 100, 0, 1000, 1000, 0, 0, 128,   606, 0, 0, 0, 0, 0, 19, 42515, 200, 0, 0, 0, 0, 0, 'Jangolode scene - Shadowy Figure anim 606'),
    (4250000, 9,  8, 0, 0, 0, 100, 0, 6000, 6000, 0, 0,   1,     2, 0, 0, 0, 0, 0, 19, 42492, 200, 0, 0, 0, 0, 0, 'Jangolode scene - Glubtok line 2'),
    (4250000, 9,  9, 0, 0, 0, 100, 0, 4100, 4100, 0, 0,   1,     3, 0, 0, 0, 0, 0, 19, 42515, 200, 0, 0, 0, 0, 0, 'Jangolode scene - Shadowy Figure line 3'),
    (4250000, 9, 10, 0, 0, 0, 100, 0, 6400, 6400, 0, 0,   1,     3, 0, 0, 0, 0, 0, 19, 42492, 200, 0, 0, 0, 0, 0, 'Jangolode scene - Glubtok line 3'),
    (4250000, 9, 11, 0, 0, 0, 100, 0, 8000, 8000, 0, 0,   1,     4, 0, 0, 0, 0, 0, 19, 42492, 200, 0, 0, 0, 0, 0, 'Jangolode scene - Glubtok line 4'),
    (4250000, 9, 12, 0, 0, 0, 100, 0, 3400, 3400, 0, 0,   1,     4, 0, 0, 0, 0, 0, 19, 42515, 200, 0, 0, 0, 0, 0, 'Jangolode scene - Shadowy Figure line 4'),
    (4250000, 9, 13, 0, 0, 0, 100, 0, 8000, 8000, 0, 0,   1,     5, 0, 0, 0, 0, 0, 19, 42515, 200, 0, 0, 0, 0, 0, 'Jangolode scene - Shadowy Figure line 5'),
    (4250000, 9, 14, 0, 0, 0, 100, 0, 2500, 2500, 0, 0,  11, 79275, 2, 0, 0, 0, 0, 23,     0,   0, 0, 0, 0, 0, 0, 'Jangolode scene - Credit owner and exit vehicle');

-- These implicit-area trigger conditions belonged to the removed relay chain.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceEntry` IN (79273, 79279, 79283, 79284, 79287, 79290, 79292, 79294, 79297);
