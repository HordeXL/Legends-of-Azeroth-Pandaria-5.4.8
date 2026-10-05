-- In Tents Channeling (30652/30657): the four channelers lower the fire shield
-- guarding Ordo Warbringer. Keep both the visual wall and its collision in a
-- dedicated phase which ends as soon as either faction version is completed.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 25
  AND `SourceGroup` = 5841
  AND `SourceEntry` = 4;

DELETE FROM `phase_definitions`
WHERE `zoneId` = 5841
  AND `entry` = 4;

INSERT INTO `phase_definitions`
    (`zoneId`, `entry`, `phasemask`, `phaseId`, `terrainswapmap`, `worldMapArea`, `flags`, `comment`)
VALUES
    (5841, 4, 134217728, 0, 0, 0, 0, 'Fire Camp Ordo - fire barrier before In Tents Channeling completion');

INSERT INTO `conditions`
    (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
     `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`,
     `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
    (25, 5841, 4, 0, 0, 28, 0, 30652, 0, 0, 1, 0, 0, '',
     'Fire barrier phase ends when Alliance In Tents Channeling is complete'),
    (25, 5841, 4, 0, 0,  8, 0, 30652, 0, 0, 1, 0, 0, '',
     'Fire barrier phase stays gone after Alliance In Tents Channeling is rewarded'),
    (25, 5841, 4, 0, 0, 28, 0, 30657, 0, 0, 1, 0, 0, '',
     'Fire barrier phase ends when Horde In Tents Channeling is complete'),
    (25, 5841, 4, 0, 0,  8, 0, 30657, 0, 0, 1, 0, 0, '',
     'Fire barrier phase stays gone after Horde In Tents Channeling is rewarded');

UPDATE `gameobject`
SET `phaseMask` = 134217728
WHERE `guid` IN (542603, 542604)
  AND `id` IN (211327, 211328);
