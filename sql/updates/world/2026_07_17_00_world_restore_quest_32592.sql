-- Restore MoP legendary-cloak quest 32592, "I Need a Champion".
--
-- Sources and mapping:
-- * TrinityCore old/6.x/world/00_2014_10_19/2014_12_29_00_world.sql
--   contains the complete source quest row (VerifiedBuild 19034).
-- * TrinityCore old/7/world/01_2018_02_19/2017_07_02_00_world.sql
--   contains the quest POI and POI point.
-- * Matching SkyFire 5.4.8 update 2014_09_04_02_world_quest_objective.sql
--   contains objective 270242 (Black Prince reputation 42000).
-- * Active quest 32591 has the same level/reward/faction/chain base and is used
--   as the current-schema donor. Its signature is guarded so no unrelated row
--   can be cloned and an existing 32592 is never overwritten.

DROP TEMPORARY TABLE IF EXISTS `_restore_quest_32592`;
CREATE TEMPORARY TABLE `_restore_quest_32592` LIKE `quest_template`;

INSERT INTO `_restore_quest_32592`
SELECT `q`.*
FROM `quest_template` AS `q`
WHERE `q`.`ID` = 32591
  AND `q`.`QuestType` = 2
  AND `q`.`QuestLevel` = 90
  AND `q`.`MinLevel` = 90
  AND `q`.`QuestPackageID` = 0
  AND `q`.`QuestSortID` = -344
  AND `q`.`QuestInfoID` = 83
  AND `q`.`RewardXPDifficulty` = 6
  AND `q`.`RewardMoney` = 228000
  AND `q`.`RewardBonusMoney` = 247200
  AND `q`.`RewardFactionID1` = 1359
  AND `q`.`RewardFactionValue1` = 5
  AND `q`.`LogTitle` = 'Secrets of the First Empire'
  AND NOT EXISTS (SELECT 1 FROM `quest_template` WHERE `ID` = 32592);

UPDATE `_restore_quest_32592`
SET `ID` = 32592,
    `RewardNextQuest` = 0,
    `RewardDisplaySpell` = 0,
    `RewardSpell` = 139524,
    `Flags` = 45088768,
    `FlagsEx` = 256,
    `LogTitle` = 'I Need a Champion',
    `LogDescription` = 'Earn Exalted Reputation with the Black Prince by defeating mogu, Zandalari, and saurok enemies on the Isle of Thunder.',
    `QuestDescription` = 'You are a superb representative of your people, $r. But I need someone special. I have big plans. And to enact them I will need a champion to carry my flame to the four corners of the world.$b$bAre you the one?$b$bProve it to me on the Isle of Thunder! Lay waste to any mogu, Zandalari, or saurok that you find. Impress me!',
    `AreaDescription` = '',
    `PortraitGiverText` = '',
    `PortraitGiverName` = '',
    `PortraitTurnInText` = '',
    `PortraitTurnInName` = '',
    `QuestCompletionLog` = 'Return to Wrathion on the second floor of the Tavern in the Mists in the Veiled Stair.',
    `VerifiedBuild` = 19034;

INSERT INTO `quest_template`
SELECT * FROM `_restore_quest_32592`;

DROP TEMPORARY TABLE `_restore_quest_32592`;

-- Quest 32591 and 32592 are the two parallel requirements after 32590; both
-- feed 32593. Copy only the exact established 32591 chain signature.
INSERT INTO `quest_template_addon`
    (`ID`, `MaxLevel`, `AllowableClasses`, `SourceSpellID`, `PrevQuestID`,
     `NextQuestID`, `ExclusiveGroup`, `RewardMailTemplateID`, `RewardMailDelay`,
     `RequiredSkillID`, `RequiredSkillPoints`, `RequiredMinRepFaction`,
     `RequiredMaxRepFaction`, `RequiredMinRepValue`, `RequiredMaxRepValue`,
     `ProvidedItemCount`, `SpecialFlags`, `ScriptName`)
SELECT 32592, `MaxLevel`, `AllowableClasses`, `SourceSpellID`, `PrevQuestID`,
       `NextQuestID`, `ExclusiveGroup`, `RewardMailTemplateID`, `RewardMailDelay`,
       `RequiredSkillID`, `RequiredSkillPoints`, `RequiredMinRepFaction`,
       `RequiredMaxRepFaction`, `RequiredMinRepValue`, `RequiredMaxRepValue`,
       `ProvidedItemCount`, `SpecialFlags`, `ScriptName`
FROM `quest_template_addon`
WHERE `ID` = 32591
  AND `PrevQuestID` = 32590
  AND `NextQuestID` = 32593
  AND `ExclusiveGroup` = -32591
  AND EXISTS (SELECT 1 FROM `quest_template` WHERE `ID` = 32592)
  AND NOT EXISTS (SELECT 1 FROM `quest_template_addon` WHERE `ID` = 32592);

-- SkyFire stores the hidden objective index as unsigned 255; this schema uses
-- signed tinyint and therefore represents the same value as -1.
INSERT INTO `quest_objective`
    (`questId`, `id`, `index`, `type`, `objectId`, `amount`, `flags`, `description`)
SELECT 32592, 270242, -1, 6, 1359, 42000, 0,
       'Earn Exalted Reputation with the Black Prince'
FROM DUAL
WHERE EXISTS (SELECT 1 FROM `quest_template` WHERE `ID` = 32592)
  AND NOT EXISTS
      (SELECT 1 FROM `quest_objective`
       WHERE `questId` = 32592 AND `id` = 270242 AND `index` = -1);

-- The old Trinity POI is identical to the active 32591 quest-start POI.
INSERT INTO `quest_poi`
    (`QuestID`, `Idx1`, `ObjectiveIndex`, `QuestObjectiveId`, `MapID`,
     `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`)
SELECT 32592, `Idx1`, `ObjectiveIndex`, `QuestObjectiveId`, `MapID`,
       `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`
FROM `quest_poi`
WHERE `QuestID` = 32591
  AND `Idx1` = 0
  AND `ObjectiveIndex` = -1
  AND `MapID` = 870
  AND `WorldMapAreaId` = 873
  AND EXISTS (SELECT 1 FROM `quest_template` WHERE `ID` = 32592)
  AND NOT EXISTS
      (SELECT 1 FROM `quest_poi` WHERE `QuestID` = 32592 AND `Idx1` = 0);

INSERT INTO `quest_poi_points`
    (`QuestID`, `BlobIndex`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 32592, `BlobIndex`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`
FROM `quest_poi_points`
WHERE `QuestID` = 32591
  AND `BlobIndex` = 0
  AND `Idx1` = 0
  AND `Idx2` = 0
  AND `X` = 832
  AND `Y` = -167
  AND EXISTS (SELECT 1 FROM `quest_template` WHERE `ID` = 32592)
  AND NOT EXISTS
      (SELECT 1 FROM `quest_poi_points`
       WHERE `QuestID` = 32592 AND `BlobIndex` = 0
         AND `Idx1` = 0 AND `Idx2` = 0);
