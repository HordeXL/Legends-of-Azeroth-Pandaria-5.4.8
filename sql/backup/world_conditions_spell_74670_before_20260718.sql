-- Exact rollback for the spell 74670 condition before the 2026-07-18 repair.

SET @corrected_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13
      AND `SourceGroup` = 1
      AND `SourceEntry` = 74670
      AND `SourceId` = 0
      AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 18
      AND `ConditionTarget` = 0
      AND `ConditionValue1` = 1
      AND `ConditionValue2` = 40040
      AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0
      AND `ErrorType` = 0
      AND `ErrorTextId` = 0
      AND `ScriptName` = ''
      AND `Comment` = 'General Umbriss - blitz'
);

SET @old_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13
      AND `SourceGroup` = 3
      AND `SourceEntry` = 74670
      AND `SourceId` = 0
      AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 18
      AND `ConditionTarget` = 0
      AND `ConditionValue1` = 1
      AND `ConditionValue2` = 40040
      AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0
      AND `ErrorType` = 0
      AND `ErrorTextId` = 0
      AND `ScriptName` = ''
      AND `Comment` = 'General Umbriss - blitz'
);

UPDATE `conditions`
SET `SourceGroup` = 3
WHERE @corrected_count = 1
  AND @old_count = 0
  AND `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 1
  AND `SourceEntry` = 74670
  AND `SourceId` = 0
  AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 18
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 1
  AND `ConditionValue2` = 40040
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` = 'General Umbriss - blitz';
