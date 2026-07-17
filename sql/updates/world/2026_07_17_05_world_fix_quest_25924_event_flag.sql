-- Call of Duty (quest 25924) is completed at the ship destination by the two
-- source-backed Erunak Stonespeaker (41618) SmartAI action-15 rows. The core
-- rejects those rows unless the exploration/event SpecialFlags bit is stored.

START TRANSACTION;

UPDATE `quest_template_addon` AS `a`
JOIN `quest_template` AS `q`
  ON `q`.`ID` = `a`.`ID`
JOIN `quest_objective` AS `o`
  ON `o`.`QuestID` = `q`.`ID`
 AND `o`.`ID` = 266797
 AND `o`.`Type` = 0
 AND `o`.`ObjectID` = 36901
 AND `o`.`Amount` = 1
SET `a`.`SpecialFlags` = `a`.`SpecialFlags` | 2
WHERE `a`.`ID` = 25924
  AND `a`.`NextQuestID` = 25929
  AND `a`.`SpecialFlags` = 0
  AND `q`.`LogTitle` = 'Call of Duty'
  AND `q`.`QuestLevel` = 81
  AND `q`.`RewardSpell` = 86596
  AND (SELECT COUNT(*)
       FROM `smart_scripts` AS `s`
       WHERE `s`.`entryorguid` = 41618
         AND `s`.`source_type` = 0
         AND `s`.`id` IN (0, 1)
         AND `s`.`event_type` = 10
         AND `s`.`action_type` = 15
         AND `s`.`action_param1` = 25924
         AND `s`.`target_type` = 7) = 2;

COMMIT;
