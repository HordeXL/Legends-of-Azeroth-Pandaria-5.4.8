-- Exact rollback for
-- 2026_08_02_07_world_remove_invalid_incantation_of_gura_implicit_target.sql.

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 1
  AND `SourceEntry` = 136909
  AND `SourceId` = 0
  AND `ElseGroup` = 0;

INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`,
 `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`,
 `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`,
 `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(13, 1, 136909, 0, 0, 31, 0, 3, 69241, 0, 0, 0, 0, '',
 'Incantation of Gura - target Gura the Reclaimed');
