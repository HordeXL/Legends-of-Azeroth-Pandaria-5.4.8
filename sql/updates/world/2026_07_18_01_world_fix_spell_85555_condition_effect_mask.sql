-- Build-18414 SpellEffect.dbc defines spell 85555 effect 0 with a nearby-entry
-- target and effect 1 with a non-area caster target. SourceGroup is an effect
-- bitmask, so 3 incorrectly applies the corpse condition to both effects.
-- Keep the condition and restrict it to effect 0 with mask 1.

SET @old_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13
      AND `SourceGroup` = 3
      AND `SourceEntry` = 85555
      AND `SourceId` = 0
      AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31
      AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3
      AND `ConditionValue2` = 45851
      AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0
      AND `ErrorType` = 0
      AND `ErrorTextId` = 0
      AND `ScriptName` = ''
      AND `Comment` = 'Burn Corpse'
);

SET @corrected_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13
      AND `SourceGroup` = 1
      AND `SourceEntry` = 85555
      AND `SourceId` = 0
      AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31
      AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3
      AND `ConditionValue2` = 45851
      AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0
      AND `ErrorType` = 0
      AND `ErrorTextId` = 0
      AND `ScriptName` = ''
      AND `Comment` = 'Burn Corpse'
);

UPDATE `conditions`
SET `SourceGroup` = 1
WHERE @old_count = 1
  AND @corrected_count = 0
  AND `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 3
  AND `SourceEntry` = 85555
  AND `SourceId` = 0
  AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3
  AND `ConditionValue2` = 45851
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` = 'Burn Corpse';
