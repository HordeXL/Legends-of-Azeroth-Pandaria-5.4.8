-- Exact rollback for
-- sql/updates/world/2026_08_04_08_world_remove_obsolete_control_ettin_80702_condition.sql
INSERT IGNORE INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
 `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
 `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
 `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(13, 2, 80702, 0, 0, 31, 0, 3, 43094, 0, 0, 0, 0, '',
 'Spell Threat targets Canyon Ettin');
