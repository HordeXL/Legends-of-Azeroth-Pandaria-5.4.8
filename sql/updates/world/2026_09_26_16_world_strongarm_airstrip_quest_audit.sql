-- Captain Doren changes entry to 66068 during combat. Killing this form
-- must still satisfy The Darkness Within's original 66052 objective.
UPDATE `creature_template` SET `KillCredit1` = 66052
WHERE `entry` = 66068 AND `KillCredit1` = 0;

-- Only players doing Unreliable Allies may free the volunteers. Guard both
-- the visible gossip option and the SmartAI event that starts the despawn.
DELETE FROM `conditions`
WHERE (`SourceTypeOrReferenceId` = 15 AND `SourceGroup` = 15119 AND `SourceEntry` = 0)
   OR (`SourceTypeOrReferenceId` = 22 AND `SourceGroup` = 1 AND `SourceEntry` = 65974 AND `SourceId` = 0);
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
 `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`,
 `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(15, 15119, 0, 0, 0, 9, 0, 31778, 0, 0, 0, 0, 0, '', 'Pandaren Volunteer gossip - Unreliable Allies active'),
(22, 1, 65974, 0, 0, 9, 0, 31778, 0, 0, 0, 0, 0, '', 'Pandaren Volunteer rescue - Unreliable Allies active');
