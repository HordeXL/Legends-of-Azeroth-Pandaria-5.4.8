-- Restore the two player-facing quests present in the 5.4.8 client but absent
-- from quest_template.  The other six missing client records are obsolete:
-- 31892/31893 (superseded pet-tamer dailies), 32010/32011 (removed in 5.1),
-- and 32458/32459 (the temporary pre-Landfall fleet event).

-- Clone the faction counterparts so every reward/display field remains in
-- lockstep with the original 5.4.8 records.
DROP TEMPORARY TABLE IF EXISTS `_tmp_missing_mop_quests_20261004`;
CREATE TEMPORARY TABLE `_tmp_missing_mop_quests_20261004` LIKE `quest_template`;
INSERT INTO `_tmp_missing_mop_quests_20261004`
SELECT * FROM `quest_template` WHERE `ID` IN (31903, 32374);

UPDATE `_tmp_missing_mop_quests_20261004`
SET `ID` = 31902,
    `AllowableRaces` = 18875469,
    `QuestDescription` = 'Now that you\'ve had a real chance to hone your skills, you\'re ready to venture out into the world of pet battles in full.$B$BThere are five tamers throughout the Eastern Kingdoms that I\'d like you to defeat: David Kosse in The Hinterlands, Deiza Plaguehorn in Eastern Plaguelands, Kortas Darkhammer in Searing Gorge, Everessa in Swamp of Sorrows, and Kortas\' brother, Durin Darkhammer, in Burning Steppes.$B$BIf you are able to best them, you will be ready to venture further.'
WHERE `ID` = 31903;

UPDATE `_tmp_missing_mop_quests_20261004`
SET `ID` = 32429,
    `AllowableRaces` = 33555378,
    `LogDescription` = 'Kill Alliance forces along the southern shores of Krasarang Wilds until you are Revered with the Black Prince.',
    `QuestDescription` = 'My goal is an expedient end to this costly war. Prove to me that the Horde deserves to win. Show me your prowess on the battlefield.$B$BYou are not fighting some abstract force like the sha: You are facing your enemy head-on, eye-to-eye.$B$BWill you triumph?'
WHERE `ID` = 32374;

REPLACE INTO `quest_template`
SELECT * FROM `_tmp_missing_mop_quests_20261004`;
DROP TEMPORARY TABLE `_tmp_missing_mop_quests_20261004`;

-- Correct faction-specific chain prerequisites.  31902/31903 are account
-- quests and open Grand Master Lydia Accoste; 32429 follows the Horde leader
-- scene in the legendary-cloak chain.
DELETE FROM `quest_template_addon` WHERE `ID` IN (31902, 32429);
INSERT INTO `quest_template_addon`
    (`ID`,`MaxLevel`,`AllowableClasses`,`SourceSpellID`,`PrevQuestID`,`NextQuestID`,`ExclusiveGroup`,
     `RewardMailTemplateID`,`RewardMailDelay`,`RequiredSkillID`,`RequiredSkillPoints`,
     `RequiredMinRepFaction`,`RequiredMaxRepFaction`,`RequiredMinRepValue`,`RequiredMaxRepValue`,
     `ProvidedItemCount`,`SpecialFlags`,`ScriptName`)
VALUES
    (31902,0,0,0,31917,31915,0,0,0,0,0,0,0,0,0,0,0,''),
    (32429,0,0,0,32427,0,0,0,0,0,0,0,0,0,0,0,0,'');

-- Repair the pre-existing Horde counterpart's omitted prerequisite too.
UPDATE `quest_template_addon`
SET `PrevQuestID` = 31918, `NextQuestID` = 31915
WHERE `ID` = 31903;

DELETE FROM `quest_objective` WHERE `questId` IN (31902, 32429);
INSERT INTO `quest_objective`
    (`questId`,`id`,`index`,`type`,`objectId`,`amount`,`flags`,`description`)
VALUES
    (31902,269176,5,11,66478,1,0,'Defeat David Kosse'),
    (31902,269177,6,11,66512,1,0,'Defeat Deiza Plaguehorn'),
    (31902,269178,7,11,66515,1,0,'Defeat Kortas Darkhammer'),
    (31902,269179,8,11,66518,1,0,'Defeat Everessa'),
    (31902,269180,9,11,66520,1,0,'Defeat Durin Darkhammer'),
    (32429,288449,0,6,1359,21000,0,'');

-- Static quest relations verified against the 5.4-era reference.  Also add
-- the relations missing from the already-present faction counterparts.
DELETE FROM `creature_queststarter` WHERE `quest` IN (31902, 32429);
DELETE FROM `creature_questender`   WHERE `quest` IN (31902, 32429);
INSERT IGNORE INTO `creature_queststarter` (`id`,`quest`) VALUES
    (63596,31902), -- Audrey Burnhep
    (63626,31903), -- Varzok
    (64616,32374), -- Wrathion, Alliance
    (64616,32429); -- Wrathion, Horde
INSERT IGNORE INTO `creature_questender` (`id`,`quest`) VALUES
    (64616,32374),
    (64616,32429);

-- Completion dialogue for the restored Horde legendary quest.
DELETE FROM `quest_offer_reward` WHERE `ID` = 32429;
INSERT INTO `quest_offer_reward`
    (`ID`,`Emote1`,`Emote2`,`Emote3`,`Emote4`,`EmoteDelay1`,`EmoteDelay2`,`EmoteDelay3`,`EmoteDelay4`,`RewardText`,`VerifiedBuild`)
VALUES
    (32429,0,0,0,0,0,0,0,0,'Marvelous! Even in the midst of the chaos of battle you\'ve proven that an individual can have an impact. The Alliance buckles under Horde might, although their King refuses to break.$B$BI believe it is time for a more substantial challenge...',17614);

-- Copy the five tamer locations from 31903, replacing its Orgrimmar starter
-- marker with Audrey's Stormwind marker.  Copy the faction-neutral Wrathion
-- marker from 32374.
DELETE FROM `quest_poi` WHERE `QuestID` IN (31902, 32429);
INSERT INTO `quest_poi`
    (`QuestID`,`Idx1`,`ObjectiveIndex`,`QuestObjectiveId`,`MapID`,`WorldMapAreaId`,`Floor`,`Priority`,`Flags`,`VerifiedBuild`)
SELECT 31902,`Idx1`,`ObjectiveIndex`,
       CASE WHEN `QuestObjectiveId` <> 0 THEN `QuestObjectiveId` - 5 ELSE 0 END,
       CASE WHEN `Idx1` = 5 THEN 0 ELSE `MapID` END,
       CASE WHEN `Idx1` = 5 THEN 301 ELSE `WorldMapAreaId` END,
       `Floor`,`Priority`,`Flags`,`VerifiedBuild`
FROM `quest_poi` WHERE `QuestID` = 31903;
INSERT INTO `quest_poi`
SELECT 32429,`Idx1`,`ObjectiveIndex`,288449,`MapID`,`WorldMapAreaId`,`Floor`,`Priority`,`Flags`,`VerifiedBuild`
FROM `quest_poi` WHERE `QuestID` = 32374;

DELETE FROM `quest_poi_points` WHERE `QuestID` IN (31902, 32429);
INSERT INTO `quest_poi_points`
    (`QuestID`,`BlobIndex`,`Idx1`,`Idx2`,`X`,`Y`,`VerifiedBuild`)
SELECT 31902,`BlobIndex`,`Idx1`,`Idx2`,
       CASE WHEN `BlobIndex` = 5 THEN -8287 ELSE `X` END,
       CASE WHEN `BlobIndex` = 5 THEN 515 ELSE `Y` END,
       `VerifiedBuild`
FROM `quest_poi_points` WHERE `QuestID` = 31903;
INSERT INTO `quest_poi_points`
SELECT 32429,`BlobIndex`,`Idx1`,`Idx2`,`X`,`Y`,`VerifiedBuild`
FROM `quest_poi_points` WHERE `QuestID` = 32374;

-- Expose the five trainers to the 5.4.8 pet-battle request opcode.  The core
-- recognizes these entries as non-capturable trainer teams and awards type-11
-- quest credit only after the full three-pet team is defeated.
UPDATE `creature_template`
SET `npcflag` = `npcflag` | 0x40000000
WHERE `entry` IN (66478,66512,66515,66518,66520);
