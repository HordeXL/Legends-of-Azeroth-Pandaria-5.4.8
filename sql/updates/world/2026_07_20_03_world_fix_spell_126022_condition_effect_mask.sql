-- Build-18414 SpellEffect.dbc contains only effect 0 for spell 126022 in both
-- available difficulty records, using TARGET_UNIT_NEARBY_ENTRY. Mask 3 also
-- includes absent effect 1. Keep the artifact filter and reduce it to mask 1.

SET @old_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13
      AND `SourceGroup` = 3
      AND `SourceEntry` = 126022
      AND `SourceId` = 0
      AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31
      AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3
      AND `ConditionValue2` = 64526
      AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0
      AND `ErrorType` = 0
      AND `ErrorTextId` = 0
      AND `ScriptName` = ''
      AND `Comment` = 'Activate Artifact - targeting Ancient Mogu Artifact'
);

SET @corrected_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13
      AND `SourceGroup` = 1
      AND `SourceEntry` = 126022
      AND `SourceId` = 0
      AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31
      AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3
      AND `ConditionValue2` = 64526
      AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0
      AND `ErrorType` = 0
      AND `ErrorTextId` = 0
      AND `ScriptName` = ''
      AND `Comment` = 'Activate Artifact - targeting Ancient Mogu Artifact'
);

UPDATE `conditions`
SET `SourceGroup` = 1
WHERE @old_count = 1
  AND @corrected_count = 0
  AND `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 3
  AND `SourceEntry` = 126022
  AND `SourceId` = 0
  AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3
  AND `ConditionValue2` = 64526
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` = 'Activate Artifact - targeting Ancient Mogu Artifact';
