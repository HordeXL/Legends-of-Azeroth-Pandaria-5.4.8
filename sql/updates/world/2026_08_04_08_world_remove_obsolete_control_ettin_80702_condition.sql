-- Saving Foreman Oslow: spell 80702 effect 1 already uses its explicit hit
-- target in Build 18414. The source-backed Control Ettin implementation
-- handles that target in SpellScript and defines implicit-target conditions
-- only for the parent spell 80704, so this old 80702 condition is obsolete
-- and is ignored by the condition loader.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 2
  AND `SourceEntry` = 80702
  AND `SourceId` = 0
  AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3
  AND `ConditionValue2` = 43094
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` = 'Spell Threat targets Canyon Ettin';
