-- Exact rollback for the four Horridon control-spell conditions before repair.

SET @corrected_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13
      AND `SourceGroup` = 2
      AND `SourceEntry` IN (137433, 137442, 137443, 137444)
      AND `SourceId` = 0
      AND `ElseGroup` = 1
      AND `ConditionTypeOrReference` = 31
      AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3
      AND `ConditionValue2` = 68476
      AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0
      AND `ErrorType` = 0
      AND `ErrorTextId` = 0
      AND `ScriptName` = ''
      AND `Comment` = 'Controll Horridon - Horridon'
);

SET @old_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13
      AND `SourceGroup` = 3
      AND `SourceEntry` IN (137433, 137442, 137443, 137444)
      AND `SourceId` = 0
      AND `ElseGroup` = 1
      AND `ConditionTypeOrReference` = 31
      AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3
      AND `ConditionValue2` = 68476
      AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0
      AND `ErrorType` = 0
      AND `ErrorTextId` = 0
      AND `ScriptName` = ''
      AND `Comment` = 'Controll Horridon - Horridon'
);

UPDATE `conditions`
SET `SourceGroup` = 3
WHERE @corrected_count = 4
  AND @old_count = 0
  AND `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 2
  AND `SourceEntry` IN (137433, 137442, 137443, 137444)
  AND `SourceId` = 0
  AND `ElseGroup` = 1
  AND `ConditionTypeOrReference` = 31
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3
  AND `ConditionValue2` = 68476
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` = 'Controll Horridon - Horridon';
