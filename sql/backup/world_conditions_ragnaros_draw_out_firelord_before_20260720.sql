-- Exact rollback for the three Draw Out Firelord conditions before the
-- 2026-07-20 effect-mask repair.

SET @corrected_100342_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 1
      AND `SourceEntry` = 100342 AND `SourceId` = 0 AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
      AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord'
);
SET @old_100342_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 7
      AND `SourceEntry` = 100342 AND `SourceId` = 0 AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
      AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord'
);
UPDATE `conditions` SET `SourceGroup` = 7
WHERE @corrected_100342_count = 1 AND @old_100342_count = 0
  AND `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 1
  AND `SourceEntry` = 100342 AND `SourceId` = 0 AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
  AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord';

SET @corrected_100344_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 1
      AND `SourceEntry` = 100344 AND `SourceId` = 0 AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
      AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord'
);
SET @old_100344_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 7
      AND `SourceEntry` = 100344 AND `SourceId` = 0 AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
      AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord'
);
UPDATE `conditions` SET `SourceGroup` = 7
WHERE @corrected_100344_count = 1 AND @old_100344_count = 0
  AND `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 1
  AND `SourceEntry` = 100344 AND `SourceId` = 0 AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
  AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord';

SET @corrected_100345_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 1
      AND `SourceEntry` = 100345 AND `SourceId` = 0 AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
      AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord'
);
SET @old_100345_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 7
      AND `SourceEntry` = 100345 AND `SourceId` = 0 AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
      AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord'
);
UPDATE `conditions` SET `SourceGroup` = 7
WHERE @corrected_100345_count = 1 AND @old_100345_count = 0
  AND `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 1
  AND `SourceEntry` = 100345 AND `SourceId` = 0 AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
  AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord';
