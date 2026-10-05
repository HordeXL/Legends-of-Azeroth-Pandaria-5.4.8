-- Lakka's rescue gossip still required the retired Brother Against Brother
-- (10097). The current dungeon quest (29605) uses the same 18956 credit.
-- A separate ElseGroup makes the two accepted quests alternatives.
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
 `ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,
 `ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`)
SELECT 15,7868,0,0,1,9,0,29605,0,0,0,0,0,'',
       'Lakka - show rescue gossip for current Brother Against Brother quest'
WHERE NOT EXISTS (
    SELECT 1 FROM `conditions`
    WHERE `SourceTypeOrReferenceId`=15 AND `SourceGroup`=7868
      AND `SourceEntry`=0 AND `SourceId`=0 AND `ElseGroup`=1
      AND `ConditionTypeOrReference`=9 AND `ConditionTarget`=0
      AND `ConditionValue1`=29605
);
