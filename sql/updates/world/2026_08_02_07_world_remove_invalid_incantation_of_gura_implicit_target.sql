-- Incantation of Gura (136909) has one Build-18414 SEND_EVENT effect with no
-- implicit unit target. Event 35098 summons Gura the Reclaimed (69241), and
-- the corrected SpellScript handles that summoned creature after the native
-- event. This target condition is therefore impossible and ignored by the
-- loader; preserve the spell cast conditions and event script unchanged.

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 1
  AND `SourceEntry` = 136909
  AND `SourceId` = 0
  AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3
  AND `ConditionValue2` = 69241
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` = 'Incantation of Gura - target Gura the Reclaimed';
