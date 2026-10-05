-- Elementary! (25303)
-- Enforce Fire -> Earth -> Air -> Water through the elemental auras carried
-- by the quest's own credit spells, and restore the missing final attacker.

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 22
  AND `SourceGroup` = 1
  AND `SourceEntry` IN (39730, 39736, 39737, 39738)
  AND `SourceId` = 0;

INSERT INTO `conditions`
    (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
     `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
     `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
     `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
    (22, 1, 39730, 0, 0, 9, 0, 25303, 0, 0, 0, 0, 0, '',
     'Elementary - Fire requires quest 25303 active'),
    (22, 1, 39730, 0, 0, 1, 0, 74287, 0, 0, 1, 0, 0, '',
     'Elementary - Fire only activates once'),

    (22, 1, 39737, 0, 0, 9, 0, 25303, 0, 0, 0, 0, 0, '',
     'Elementary - Earth requires quest 25303 active'),
    (22, 1, 39737, 0, 0, 1, 0, 74287, 0, 0, 0, 0, 0, '',
     'Elementary - Earth requires Aura of Fire'),
    (22, 1, 39737, 0, 0, 1, 0, 74288, 0, 0, 1, 0, 0, '',
     'Elementary - Earth only activates once'),

    (22, 1, 39736, 0, 0, 9, 0, 25303, 0, 0, 0, 0, 0, '',
     'Elementary - Air requires quest 25303 active'),
    (22, 1, 39736, 0, 0, 1, 0, 74288, 0, 0, 0, 0, 0, '',
     'Elementary - Air requires Aura of Earth'),
    (22, 1, 39736, 0, 0, 1, 0, 74290, 0, 0, 1, 0, 0, '',
     'Elementary - Air only activates once'),

    (22, 1, 39738, 0, 0, 9, 0, 25303, 0, 0, 0, 0, 0, '',
     'Elementary - Water requires quest 25303 active'),
    (22, 1, 39738, 0, 0, 1, 0, 74290, 0, 0, 0, 0, 0, '',
     'Elementary - Water requires Aura of Air'),
    (22, 1, 39738, 0, 0, 1, 0, 74292, 0, 0, 1, 0, 0, '',
     'Elementary - Water only activates once');

UPDATE `smart_scripts`
SET `link` = 2,
    `comment` = 'Crucible of Water - close gossip and summon The Manipulator'
WHERE `entryorguid` = 39738
  AND `source_type` = 0
  AND `id` = 1
  AND `event_type` = 61
  AND `action_type` = 72;

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 39738
  AND `source_type` = 0
  AND `id` = 2;

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
     `event_chance`, `event_flags`, `event_param1`, `event_param2`,
     `event_param3`, `event_param4`, `event_param5`, `action_type`,
     `action_param1`, `action_param2`, `action_param3`, `action_param4`,
     `action_param5`, `action_param6`, `target_type`, `target_param1`,
     `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`,
     `target_o`, `comment`)
VALUES
    (39738, 0, 2, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 12,
     39756, 2, 180000, 1, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0,
     'Crucible of Water - summon The Manipulator on player and attack');
