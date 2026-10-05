-- Konk remains available to players who have not completed Seein' Red,
-- but must not reappear for a player after the kill objective is complete.
START TRANSACTION;
UPDATE `creature` SET `phaseMask` = 536870912
WHERE `guid` = 500004 AND `id` = 55509 AND `map` = 870;

DELETE FROM `phase_definitions` WHERE `zoneId` = 5785 AND `entry` = 6;
INSERT INTO `phase_definitions`
(`zoneId`, `entry`, `phasemask`, `phaseId`, `terrainswapmap`, `worldMapArea`, `flags`, `comment`)
VALUES (5785, 6, 536870912, 0, 0, 0, 0, 'Jade Forest - Konk before Seein Red is complete');

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 25 AND `SourceGroup` = 5785 AND `SourceEntry` = 6;
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
 `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`,
 `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(25, 5785, 6, 0, 0, 8, 0, 29804, 0, 0, 1, 0, 0, '', 'Konk - Seein Red not rewarded'),
(25, 5785, 6, 0, 0, 28, 0, 29804, 0, 0, 1, 0, 0, '', 'Konk - Seein Red not complete');
COMMIT;
