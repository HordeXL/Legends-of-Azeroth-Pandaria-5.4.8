-- Keep the destroyed stair barricades out of a player's phase after
-- The Final Blow! (31769), including the completed but not rewarded state.
-- Other players still see the barricades until they finish that quest.
START TRANSACTION;

UPDATE `gameobject` SET `phaseMask` = 1073741824
WHERE `map` = 870 AND `id` IN (215646, 215647)
  AND `guid` IN (545757, 545758, 545759, 545760, 545761);

UPDATE `creature` SET `phaseMask` = 1073741824
WHERE `map` = 870 AND `id` IN (66554, 66555, 66556)
  AND `guid` IN (570805, 570806, 570807, 570808);

DELETE FROM `phase_definitions` WHERE `zoneId` = 5785 AND `entry` = 5;
INSERT INTO `phase_definitions`
(`zoneId`, `entry`, `phasemask`, `phaseId`, `terrainswapmap`, `worldMapArea`, `flags`, `comment`)
VALUES (5785, 5, 1073741824, 0, 0, 0, 0, 'Jade Forest - stair barricades before The Final Blow is complete');

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 25 AND `SourceGroup` = 5785 AND `SourceEntry` = 5;
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
 `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`,
 `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(25, 5785, 5, 0, 0, 8, 0, 31769, 0, 0, 1, 0, 0, '', 'Stair barricades - The Final Blow not rewarded'),
(25, 5785, 5, 0, 0, 28, 0, 31769, 0, 0, 1, 0, 0, '', 'Stair barricades - The Final Blow not complete');

COMMIT;
