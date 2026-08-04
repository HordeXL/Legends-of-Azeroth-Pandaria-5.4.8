-- Exact rollback for
-- sql/updates/world/2026_08_04_04_world_remove_obsolete_maloriak_bottle_conditions.sql
INSERT IGNORE INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
 `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`,
 `ConditionValue1`, `ConditionValue2`, `ConditionValue3`,
 `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(13, 1, 77925, 0, 0, 31, 0, 3, 41505, 0, 0, 0, 0, '',
 'throw red bottle'),
(13, 1, 77932, 0, 0, 31, 0, 3, 41505, 0, 0, 0, 0, '',
 'throw blue bottle'),
(13, 1, 77937, 0, 0, 31, 0, 3, 41505, 0, 0, 0, 0, '',
 'bthrow green bottle'),
(13, 1, 92831, 0, 0, 31, 0, 3, 41505, 0, 0, 0, 0, '',
 'throw black bottle');
