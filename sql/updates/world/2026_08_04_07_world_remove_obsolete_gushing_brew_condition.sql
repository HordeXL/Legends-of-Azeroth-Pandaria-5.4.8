-- Stormstout Brewery: spell 114379 already has an explicit unit target in
-- Build 18414. The instance script finds the nearest flying bunny (54020) and
-- casts directly on it, so this old implicit-target proximity condition is
-- redundant and is ignored during startup.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 1
  AND `SourceEntry` = 114379
  AND `SourceId` = 0
  AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 29
  AND `ConditionTarget` = 1
  AND `ConditionValue1` = 54020
  AND `ConditionValue2` = 15
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` IS NULL;
