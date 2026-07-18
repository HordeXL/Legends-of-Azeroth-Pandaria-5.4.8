-- Each Build-18414 Horridon control spell uses effect 0 on the caster and
-- effect 1 with TARGET_UNIT_NEARBY_ENTRY to find Horridon (68476). Keep all
-- four entry conditions and restrict mask 3 to the intended effect-1 mask 2.

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

UPDATE `conditions`
SET `SourceGroup` = 2
WHERE @old_count = 4
  AND @corrected_count = 0
  AND `SourceTypeOrReferenceId` = 13
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
  AND `Comment` = 'Controll Horridon - Horridon';
