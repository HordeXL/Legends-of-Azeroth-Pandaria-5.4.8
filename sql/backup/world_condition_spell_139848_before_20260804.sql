-- Exact rollback for
-- sql/updates/world/2026_08_04_02_world_remove_obsolete_acid_rain_missile_condition.sql
INSERT IGNORE INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
 `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
 `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
 `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(13, 1, 139848, 0, 0, 31, 0, 3, 70435, 0, 0, 0, 0, '',
 'Acid Rain Missle - Target Acid Rain Dummy');
