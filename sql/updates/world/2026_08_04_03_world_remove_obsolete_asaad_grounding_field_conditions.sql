-- Asaad: SpellMgr converts 86911 and all three effects of 87517 to explicit
-- unit targets. The encounter script casts 86911 directly between the three
-- summoned Unstable Grounding Field creatures (46492). These old area-entry
-- conditions cannot be evaluated and are ignored during startup.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 1
  AND `SourceEntry` IN (86911, 87517)
  AND `SourceId` = 0
  AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3
  AND `ConditionValue2` = 46492
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` = 'Asaad - Grounding field visual beams';
