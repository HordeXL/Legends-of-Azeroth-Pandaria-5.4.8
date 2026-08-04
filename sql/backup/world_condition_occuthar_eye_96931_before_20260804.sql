-- Exact rollback for
-- sql/updates/world/2026_08_04_05_world_remove_obsolete_occuthar_eye_condition.sql
INSERT IGNORE INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
 `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
 `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
 `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(13, 1, 96931, 0, 0, 31, 0, 3, 52368, 0, 0, 0, 0, '', '');
