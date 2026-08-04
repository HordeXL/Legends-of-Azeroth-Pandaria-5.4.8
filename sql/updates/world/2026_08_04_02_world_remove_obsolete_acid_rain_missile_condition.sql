-- Megaera: the current C++ implementation summons Acid Rain (70435) and
-- explicitly casts spell 139848 on that summoned unit. SpellMgr also changes
-- effect 0 to an explicit unit target, so this old area-entry condition cannot
-- be evaluated and is ignored during startup.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 1
  AND `SourceEntry` = 139848
  AND `SourceId` = 0
  AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3
  AND `ConditionValue2` = 70435
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` = 'Acid Rain Missle - Target Acid Rain Dummy';
