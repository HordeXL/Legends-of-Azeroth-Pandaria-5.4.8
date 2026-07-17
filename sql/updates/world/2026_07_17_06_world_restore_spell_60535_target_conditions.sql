-- Restore the matching SkyFire 5.4.8 target conditions for spell 60535.
-- The local pre-fix rows retained the target creature IDs in ConditionValue2,
-- but SourceGroup, ElseGroup, condition type and ConditionValue1 were corrupted.
-- No condition is deleted; this update changes only the 21 exact old rows.

SET @old_count := (
    SELECT COUNT(*)
    FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13
      AND `SourceGroup` = 0
      AND `SourceEntry` = 60535
      AND `SourceId` = 0
      AND `ElseGroup` = 0
      AND `ConditionTypeOrReference` = 18
      AND `ConditionTarget` = 0
      AND `ConditionValue1` = 0
      AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0
      AND `ErrorType` = 0
      AND `ErrorTextId` = 0
      AND `ScriptName` = ''
      AND `Comment` IS NULL
      AND `ConditionValue2` IN (191440, 191444, 191445, 191665, 192067, 192069, 192070,
                                192083, 192084, 192085, 192086, 192087, 192088, 192089,
                                192116, 192117, 192119, 192850, 192852, 192853, 192854)
);

SET @corrected_count := (
    SELECT COUNT(*)
    FROM `conditions`
    WHERE `SourceTypeOrReferenceId` = 13
      AND `SourceGroup` = 1
      AND `SourceEntry` = 60535
      AND `SourceId` = 0
      AND `ConditionTypeOrReference` = 31
      AND `ConditionTarget` = 0
      AND `ConditionValue1` = 5
      AND `ConditionValue3` = 0
      AND `NegativeCondition` = 0
      AND `ErrorType` = 0
      AND `ErrorTextId` = 0
      AND `ScriptName` = ''
      AND `Comment` IS NULL
      AND `ConditionValue2` IN (191440, 191444, 191445, 191665, 192067, 192069, 192070,
                                192083, 192084, 192085, 192086, 192087, 192088, 192089,
                                192116, 192117, 192119, 192850, 192852, 192853, 192854)
);

UPDATE `conditions`
SET `SourceGroup` = 1,
    `ElseGroup` = CASE `ConditionValue2`
        WHEN 191440 THEN 0 WHEN 191444 THEN 1 WHEN 191445 THEN 2 WHEN 191665 THEN 3
        WHEN 192067 THEN 4 WHEN 192069 THEN 5 WHEN 192070 THEN 6 WHEN 192083 THEN 7
        WHEN 192084 THEN 8 WHEN 192085 THEN 9 WHEN 192086 THEN 10 WHEN 192087 THEN 11
        WHEN 192088 THEN 12 WHEN 192089 THEN 13 WHEN 192116 THEN 14 WHEN 192117 THEN 15
        WHEN 192119 THEN 16 WHEN 192850 THEN 17 WHEN 192852 THEN 18 WHEN 192853 THEN 19
        WHEN 192854 THEN 20 END,
    `ConditionTypeOrReference` = 31,
    `ConditionValue1` = 5
WHERE @old_count = 21
  AND @corrected_count = 0
  AND `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 0
  AND `SourceEntry` = 60535
  AND `SourceId` = 0
  AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 18
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 0
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` IS NULL
  AND `ConditionValue2` IN (191440, 191444, 191445, 191665, 192067, 192069, 192070,
                            192083, 192084, 192085, 192086, 192087, 192088, 192089,
                            192116, 192117, 192119, 192850, 192852, 192853, 192854);
