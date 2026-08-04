-- Exact rollback for
-- sql/updates/world/2026_08_04_01_world_remove_stale_spray_water_condition.sql
INSERT IGNORE INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
 `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
 `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
 `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(13, 1, 80199, 0, 0, 31, 0, 3, 42940, 0, 0, 0, 0, '', '');
