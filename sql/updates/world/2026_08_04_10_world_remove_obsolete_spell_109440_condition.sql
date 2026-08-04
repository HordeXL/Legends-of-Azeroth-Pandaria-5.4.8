-- Dragon Soul: Build 18414 spell 109440 is a caster aura used by Hagara's
-- summoned Tornado Stalker (57921), and it periodically triggers 109441.
-- Ultraxion's Gift of Life chain does not use 109440. This old implicit-target
-- condition against General Purpose Bunny JMF (45979) is therefore obsolete
-- and is ignored by the condition loader.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 1
  AND `SourceEntry` = 109440
  AND `SourceId` = 0
  AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3
  AND `ConditionValue2` = 45979
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` = 'Ultraxion - Gift of Live';
