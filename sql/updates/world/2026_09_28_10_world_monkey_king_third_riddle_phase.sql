-- The Monkey King (68130) is the challenger for The Third Riddle: Strength
-- and must not be visible as a permanent hostile elite at the Tiger Temple.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 25
  AND `SourceGroup` = 5841
  AND `SourceEntry` = 3;

DELETE FROM `phase_definitions`
WHERE `zoneId` = 5841
  AND `entry` = 3;

INSERT INTO `phase_definitions`
    (`zoneId`, `entry`, `phasemask`, `phaseId`, `terrainswapmap`, `worldMapArea`, `flags`, `comment`)
VALUES
    (5841, 3, 268435456, 0, 0, 0, 0, 'Tiger Temple - The Third Riddle: Strength challenger');

INSERT INTO `conditions`
    (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
     `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`,
     `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
    (25, 5841, 3, 0, 0, 9, 0, 32334, 0, 0, 0, 0, 0, '',
     'Monkey King challenger phase requires active The Third Riddle: Strength');

UPDATE `creature`
SET `phaseMask` = 268435456
WHERE `guid` = 510061
  AND `id` = 68130;
