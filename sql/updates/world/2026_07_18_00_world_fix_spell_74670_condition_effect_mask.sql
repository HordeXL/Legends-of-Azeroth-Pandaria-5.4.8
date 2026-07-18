-- Build-18414 SpellEffect.dbc defines spell 74670 effect 0 with a nearby-entry
-- target and effect 1 with a non-area destination target. SourceGroup is an
-- effect bitmask, so 3 incorrectly applies this condition to both effects.
-- Keep the condition and restrict it to the intended effect 0 with mask 1.

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

UPDATE `conditions`
SET `SourceGroup` = 1
WHERE @old_count = 1
  AND @corrected_count = 0
  AND `SourceTypeOrReferenceId` = 13
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
  AND `Comment` = 'General Umbriss - blitz';
