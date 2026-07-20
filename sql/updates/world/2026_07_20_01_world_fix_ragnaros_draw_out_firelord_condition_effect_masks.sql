-- The Draw Out Firelord Ragnaros filter belongs only to effect 0 of all three
-- cosmetic beam spells. Build-18414 SpellEffect.dbc has no effects 1/2 for
-- 100342 or 100344. Spell 100345 has a caster-targeted trigger at effect 1 and
-- no effect 2. Preserve each Ragnaros condition and narrow masks 7 to mask 1.

SET @old_100342_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 7
      AND `SourceEntry` = 100342 AND `SourceId` = 0 AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
      AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord'
);
SET @corrected_100342_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 1
      AND `SourceEntry` = 100342 AND `SourceId` = 0 AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
      AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord'
);
UPDATE `conditions` SET `SourceGroup` = 1
WHERE @old_100342_count = 1 AND @corrected_100342_count = 0
  AND `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 7
  AND `SourceEntry` = 100342 AND `SourceId` = 0 AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
  AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord';

SET @old_100344_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 7
      AND `SourceEntry` = 100344 AND `SourceId` = 0 AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
      AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord'
);
SET @corrected_100344_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 1
      AND `SourceEntry` = 100344 AND `SourceId` = 0 AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
      AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord'
);
UPDATE `conditions` SET `SourceGroup` = 1
WHERE @old_100344_count = 1 AND @corrected_100344_count = 0
  AND `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 7
  AND `SourceEntry` = 100344 AND `SourceId` = 0 AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
  AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord';

SET @old_100345_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 7
      AND `SourceEntry` = 100345 AND `SourceId` = 0 AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
      AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord'
);
SET @corrected_100345_count := (
    SELECT COUNT(*) FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 1
      AND `SourceEntry` = 100345 AND `SourceId` = 0 AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
      AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
      AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord'
);
UPDATE `conditions` SET `SourceGroup` = 1
WHERE @old_100345_count = 1 AND @corrected_100345_count = 0
  AND `SourceTypeOrReferenceId` = 13 AND `SourceGroup` = 7
  AND `SourceEntry` = 100345 AND `SourceId` = 0 AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31 AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3 AND `ConditionValue2` = 52409 AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0 AND `ErrorType` = 0 AND `ErrorTextId` = 0
  AND `ScriptName` = '' AND `Comment` = 'Ragnaros Firelands - Draw Out Firelord';
