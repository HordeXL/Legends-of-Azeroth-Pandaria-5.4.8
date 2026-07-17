-- Area-trigger quest relations require QUEST_SPECIAL_FLAGS_EXPLORATION_OR_EVENT.
-- The core otherwise adds bit 2 only in memory and logs the same warnings on
-- every startup. Both preserved pre-fix project dumps confirm all 13 exact
-- trigger-to-quest mappings; this update does not rewrite those relationships.
--
-- For the 11 existing addon rows, preserve every other bit/field and add bit 2
-- only when the exact relation and the matching type-10 objective still exist.

UPDATE `quest_template_addon` AS `qa`
JOIN
(
    SELECT 5483 AS `TriggerID`,   869 AS `QuestID`, 255104 AS `ObjectiveID`
    UNION ALL SELECT 5972, 13564, 267649
    UNION ALL SELECT 5482, 14066, 264415
    UNION ALL SELECT 5881, 25621, 267090
    UNION ALL SELECT 6034, 26512, 266334
    UNION ALL SELECT 6213, 26930, 253678
    UNION ALL SELECT 6221, 27007, 267510
    UNION ALL SELECT 6238, 27152, 261620
    UNION ALL SELECT 6245, 27610, 262110
    UNION ALL SELECT 6911, 29392, 251754
    UNION ALL SELECT 6920, 29415, 251893
) AS `m` ON `m`.`QuestID` = `qa`.`ID`
JOIN `areatrigger_involvedrelation` AS `a`
  ON `a`.`id` = `m`.`TriggerID` AND `a`.`quest` = `m`.`QuestID`
JOIN `quest_objective` AS `qo`
  ON `qo`.`questId` = `m`.`QuestID`
 AND `qo`.`id` = `m`.`ObjectiveID`
 AND `qo`.`type` = 10
 AND `qo`.`objectId` = 0
SET `qa`.`SpecialFlags` = (`qa`.`SpecialFlags` | 2)
WHERE `qa`.`SpecialFlags` = 0;

-- Quests 29536 and 29539 had no addon row in either preserved project dump.
-- Insert only the schema defaults plus the required bit, guarded by their exact
-- active quest, objective, and areatrigger signatures. Existing rows are never
-- overwritten.
INSERT INTO `quest_template_addon`
    (`ID`, `MaxLevel`, `AllowableClasses`, `SourceSpellID`, `PrevQuestID`,
     `NextQuestID`, `ExclusiveGroup`, `RewardMailTemplateID`, `RewardMailDelay`,
     `RequiredSkillID`, `RequiredSkillPoints`, `RequiredMinRepFaction`,
     `RequiredMaxRepFaction`, `RequiredMinRepValue`, `RequiredMaxRepValue`,
     `ProvidedItemCount`, `SpecialFlags`, `ScriptName`)
SELECT `q`.`ID`, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, ''
FROM `quest_template` AS `q`
JOIN
(
    SELECT 4201 AS `TriggerID`, 29536 AS `QuestID`, 253700 AS `ObjectiveID`
    UNION ALL SELECT 4200, 29539, 256531
) AS `m` ON `m`.`QuestID` = `q`.`ID`
JOIN `areatrigger_involvedrelation` AS `a`
  ON `a`.`id` = `m`.`TriggerID` AND `a`.`quest` = `m`.`QuestID`
JOIN `quest_objective` AS `qo`
  ON `qo`.`questId` = `m`.`QuestID`
 AND `qo`.`id` = `m`.`ObjectiveID`
 AND `qo`.`type` = 10
 AND `qo`.`objectId` = 0
WHERE `q`.`QuestType` = 2
  AND `q`.`QuestLevel` = 63
  AND `q`.`Flags` = 140
  AND `q`.`LogTitle` = 'Heart of Rage'
  AND NOT EXISTS
      (SELECT 1 FROM `quest_template_addon` WHERE `ID` = `q`.`ID`);
