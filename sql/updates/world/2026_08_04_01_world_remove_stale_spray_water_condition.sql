-- Quest 26391 "Extinguishing Hope": spell 80199 targets the caster and
-- triggers spell 80208. The entry-filter condition belongs to 80208, where
-- the correct condition already exists. The 80199 row cannot be evaluated
-- by the core and is ignored during startup.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 1
  AND `SourceEntry` = 80199
  AND `SourceId` = 0
  AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3
  AND `ConditionValue2` = 42940
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` = '';
