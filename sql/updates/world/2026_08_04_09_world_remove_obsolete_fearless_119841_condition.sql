-- Terrace of Endless Spring: the matching 5.4.8 core deliberately changes
-- both Fearless (119841) destination targets to TARGET_DEST_DB. The two exact
-- spell_target_position rows provide those destinations, so this old
-- creature-entry implicit-target condition is obsolete and ignored.
DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 13
  AND `SourceGroup` = 3
  AND `SourceEntry` = 119841
  AND `SourceId` = 0
  AND `ElseGroup` = 0
  AND `ConditionTypeOrReference` = 31
  AND `ConditionTarget` = 0
  AND `ConditionValue1` = 3
  AND `ConditionValue2` = 60788
  AND `ConditionValue3` = 0
  AND `NegativeCondition` = 0
  AND `ErrorType` = 0
  AND `ErrorTextId` = 0
  AND `ScriptName` = ''
  AND `Comment` = 'fearless - target Light';
