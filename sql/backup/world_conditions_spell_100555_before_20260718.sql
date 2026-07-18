-- Exact rollback for the spell 100555 condition before the 2026-07-18 repair.

SET @corrected_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13
      AND `SourceGroup` = 2
      AND `SourceEntry` = 100555
      AND `SourceId` = 0
      AND `ElseGroup` = 1
      AND `ConditionTypeOrReference` = 31
      AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3
      AND `ConditionValue2` = 47242
      AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0
      AND `ErrorType` = 0
      AND `ErrorTextId` = 0
      AND `ScriptName` = ''
      AND `Comment` = 'Smouldering Roots - Alysra Event'
);

SET @old_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13
      AND `SourceGroup` = 3
      AND `SourceEntry` = 100555
      AND `SourceId` = 0
      AND `ElseGroup` = 1
      AND `ConditionTypeOrReference` = 31
      AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3
      AND `ConditionValue2` = 47242
      AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0
      AND `ErrorType` = 0
      AND `ErrorTextId` = 0
      AND `ScriptName` = ''
      AND `Comment` = 'Smouldering Roots - Alysra Event'
);

UPDATE `conditions`
SET `SourceGroup` = 3
WHERE @corrected_count = 1
  AND @old_count = 0
  AND `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 2
  AND `SourceEntry` = 100555
  AND `SourceId` = 0
  AND `ElseGroup` = 1
  AND `ConditionTypeOrReference` = 31
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3
  AND `ConditionValue2` = 47242
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` = 'Smouldering Roots - Alysra Event';
