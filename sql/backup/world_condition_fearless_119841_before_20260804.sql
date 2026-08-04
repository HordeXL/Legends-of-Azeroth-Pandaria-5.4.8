-- Exact rollback for
-- sql/updates/world/2026_08_04_09_world_remove_obsolete_fearless_119841_condition.sql
INSERT IGNORE INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
 `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
 `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
 `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(13, 3, 119841, 0, 0, 31, 0, 3, 60788, 0, 0, 0, 0, '',
 'fearless - target Light');
