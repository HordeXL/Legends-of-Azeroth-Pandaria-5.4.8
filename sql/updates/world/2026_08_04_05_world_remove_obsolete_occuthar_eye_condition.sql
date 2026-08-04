-- Occu'thar: this condition is inherited from an old 4.3.4 Eyestalk setup.
-- The current core makes spell 96931 target its caster, and the bound
-- SpellScript explicitly summons Eye of Occu'thar (52389) and applies damage.
-- The old 52368 area-entry condition is ignored during startup.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 1
  AND `SourceEntry` = 96931
  AND `SourceId` = 0
  AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3
  AND `ConditionValue2` = 52368
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` = '';
