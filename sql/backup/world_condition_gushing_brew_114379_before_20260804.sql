-- Exact rollback for
-- sql/updates/world/2026_08_04_07_world_remove_obsolete_gushing_brew_condition.sql
INSERT IGNORE INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
 `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
 `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
 `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(13, 1, 114379, 0, 0, 29, 1, 54020, 15, 0, 0, 0, 0, '', NULL);
