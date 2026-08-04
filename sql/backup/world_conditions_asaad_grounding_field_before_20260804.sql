-- Exact rollback for
-- sql/updates/world/2026_08_04_03_world_remove_obsolete_asaad_grounding_field_conditions.sql
INSERT IGNORE INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
 `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
 `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
 `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(13, 1, 86911, 0, 0, 31, 0, 3, 46492, 0, 0, 0, 0, '',
 'Asaad - Grounding field visual beams'),
(13, 1, 87517, 0, 0, 31, 0, 3, 46492, 0, 0, 0, 0, '',
 'Asaad - Grounding field visual beams');
