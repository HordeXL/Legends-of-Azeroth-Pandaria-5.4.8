-- Exact rollback for the three Magnetic Crush conditions before repair.

SET @corrected_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13
      AND ((`SourceEntry` = 143487 AND `SourceGroup` = 2)
        OR (`SourceEntry` IN (147369, 147370) AND `SourceGroup` = 4))
      AND `SourceId` = 0
      AND `ElseGroup` = 1
      AND `ConditionTypeOrReference` = 31
      AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3
      AND `ConditionValue2` = 71520
      AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0
      AND `ErrorType` = 0
      AND `ErrorTextId` = 0
      AND `ScriptName` = ''
      AND `Comment` = 'Magnetic Crush - by Siegecrafter Blackfuse'
);

SET @old_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13
      AND `SourceGroup` = 1
      AND `SourceEntry` IN (143487, 147369, 147370)
      AND `SourceId` = 0
      AND `ElseGroup` = 1
      AND `ConditionTypeOrReference` = 31
      AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3
      AND `ConditionValue2` = 71520
      AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0
      AND `ErrorType` = 0
      AND `ErrorTextId` = 0
      AND `ScriptName` = ''
      AND `Comment` = 'Magnetic Crush - by Siegecrafter Blackfuse'
);

UPDATE `conditions`
SET `SourceGroup` = 1
WHERE @corrected_count = 3
  AND @old_count = 0
  AND `SourceTypeOrReferenceId` = 13
  AND ((`SourceEntry` = 143487 AND `SourceGroup` = 2)
    OR (`SourceEntry` IN (147369, 147370) AND `SourceGroup` = 4))
  AND `SourceId` = 0
  AND `ElseGroup` = 1
  AND `ConditionTypeOrReference` = 31
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3
  AND `ConditionValue2` = 71520
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` = 'Magnetic Crush - by Siegecrafter Blackfuse';
