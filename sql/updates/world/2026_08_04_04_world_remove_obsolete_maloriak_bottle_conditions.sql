-- Maloriak: SpellMgr converts the bottle spells to explicit GameObject
-- targets. The encounter scripts find cauldron GO 203306 and cast directly on
-- it; spell_maloriak_throw_bottle requires GetHitGObj(). These old filters for
-- creature 41505 cannot be evaluated and are ignored during startup.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 1
  AND `SourceEntry` IN (77925, 77932, 77937, 92831)
  AND `SourceId` = 0
  AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3
  AND `ConditionValue2` = 41505
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` IN
      ('throw red bottle', 'throw blue bottle', 'bthrow green bottle',
       'throw black bottle');
