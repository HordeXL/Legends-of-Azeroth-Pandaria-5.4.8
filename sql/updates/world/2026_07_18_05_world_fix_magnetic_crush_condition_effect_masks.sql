-- Build-18414 spell 143487 creates its area trigger on effect 1, while the
-- heroic pair 147369/147370 creates it on effect 2. All three use
-- TARGET_DEST_NEARBY_ENTRY to locate helper 71520. Keep every condition and
-- move it from the incorrect effect-0 mask 1 to masks 2 and 4 respectively.

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

UPDATE `conditions`
SET `SourceGroup` = 2
WHERE @old_count = 3
  AND @corrected_count = 0
  AND `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 1
  AND `SourceEntry` = 143487
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

UPDATE `conditions`
SET `SourceGroup` = 4
WHERE @old_count = 3
  AND @corrected_count = 0
  AND `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 1
  AND `SourceEntry` IN (147369, 147370)
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
