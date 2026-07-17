-- Quest-complete spell effects require QUEST_SPECIAL_FLAGS_EXPLORATION_OR_EVENT.
-- ObjectMgr validates this relationship and otherwise adds the missing bit only
-- in memory on every startup. Preserve the existing repeatable bit and add bit 2.
--
-- Fresh startup evidence:
-- * spell 114741 completes quest 30470;
-- * spell 139912 completes quests 32640 and 32641.
--
-- This update is guarded by the exact active quest signatures and changes no
-- other quest-addon field. Reapplication is idempotent.

UPDATE `quest_template_addon` AS `qa`
JOIN `quest_template` AS `q` ON `q`.`ID` = `qa`.`ID`
SET `qa`.`SpecialFlags` = (`qa`.`SpecialFlags` | 2)
WHERE `qa`.`ID` = 30470
  AND `qa`.`SpecialFlags` = 1
  AND `q`.`QuestType` = 2
  AND `q`.`QuestLevel` = 90
  AND `q`.`Flags` = 4096
  AND `q`.`LogTitle` = 'A Gift For Tina';

UPDATE `quest_template_addon` AS `qa`
JOIN `quest_template` AS `q` ON `q`.`ID` = `qa`.`ID`
SET `qa`.`SpecialFlags` = (`qa`.`SpecialFlags` | 2)
WHERE `qa`.`ID` IN (32640, 32641)
  AND `qa`.`SpecialFlags` = 1
  AND `qa`.`PrevQuestID` = 32708
  AND `q`.`QuestType` = 2
  AND `q`.`QuestLevel` = 90
  AND `q`.`Flags` = 36732936
  AND `q`.`LogTitle` = 'Champions of the Thunder King';
