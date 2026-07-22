-- Restore two 5.4.8-source-backed quest POI points that were left without a
-- matching point after the old quest-POI merge/reindex operation.
--
-- Matching SkyFire 5.4.8 SFDB data defines both rows as the general/return
-- POI (ObjectiveIndex = -1) with these exact coordinates:
--   6922 / old POI 0 -> active POI 1:  3355, 1033
--   8306 / old POI 0 -> active POI 1: -6752,  824
-- The second coordinate also already exists in this database under the
-- displaced POI index 2. No parent POI or existing point is deleted/rewritten.

-- CREATE TABLE implicitly commits in MySQL 5.7, so create and populate the
-- persistent exact-row backup before starting the data transaction.
CREATE TABLE IF NOT EXISTS `_backup_quest_poi_points_6922_8306_20260722`
LIKE `quest_poi_points`;

INSERT IGNORE INTO `_backup_quest_poi_points_6922_8306_20260722`
SELECT *
FROM `quest_poi_points`
WHERE (`QuestID` = 6922 AND `BlobIndex` = 0 AND `Idx1` = 2
       AND `Idx2` = 0 AND `X` = -157 AND `Y` = 74)
   OR (`QuestID` = 8306 AND `BlobIndex` = 0 AND `Idx1` = 0
       AND `Idx2` = 0 AND `X` = -8325 AND `Y` = 728)
   OR (`QuestID` = 8306 AND `BlobIndex` = 1 AND `Idx1` = 2
       AND `Idx2` = 0 AND `X` = -6752 AND `Y` = 824)
   OR (`QuestID` = 8306 AND `BlobIndex` = 1 AND `Idx1` = 2
       AND `Idx2` = 1 AND `X` = -6752 AND `Y` = 824);

START TRANSACTION;

SET @quest_poi_6922_8306_backup_ok :=
(
    SELECT COUNT(*) = 4
       AND SUM(`QuestID` = 6922 AND `BlobIndex` = 0 AND `Idx1` = 2
               AND `Idx2` = 0 AND `X` = -157 AND `Y` = 74) = 1
       AND SUM(`QuestID` = 8306 AND `BlobIndex` = 0 AND `Idx1` = 0
               AND `Idx2` = 0 AND `X` = -8325 AND `Y` = 728) = 1
       AND SUM(`QuestID` = 8306 AND `BlobIndex` = 1 AND `Idx1` = 2
               AND `Idx2` = 0 AND `X` = -6752 AND `Y` = 824) = 1
       AND SUM(`QuestID` = 8306 AND `BlobIndex` = 1 AND `Idx1` = 2
               AND `Idx2` = 1 AND `X` = -6752 AND `Y` = 824) = 1
    FROM `_backup_quest_poi_points_6922_8306_20260722`
);

INSERT IGNORE INTO `quest_poi_points`
    (`QuestID`, `BlobIndex`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 6922, 0, 1, 0, 3355, 1033, 0
FROM DUAL
WHERE @quest_poi_6922_8306_backup_ok = 1
  AND EXISTS
      (SELECT 1 FROM `quest_poi`
       WHERE `QuestID` = 6922 AND `Idx1` = 1
         AND `ObjectiveIndex` = -1 AND `QuestObjectiveId` = 0
         AND `MapID` = 1 AND `WorldMapAreaId` = 43
         AND `Floor` = 0 AND `Flags` = 7)
  AND NOT EXISTS
      (SELECT 1 FROM `quest_poi_points`
       WHERE `QuestID` = 6922 AND `Idx1` = 1);

INSERT IGNORE INTO `quest_poi_points`
    (`QuestID`, `BlobIndex`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 8306, 0, 1, 0, source.`X`, source.`Y`, source.`VerifiedBuild`
FROM `quest_poi_points` source
WHERE @quest_poi_6922_8306_backup_ok = 1
  AND source.`QuestID` = 8306 AND source.`BlobIndex` = 1
  AND source.`Idx1` = 2 AND source.`Idx2` = 0
  AND source.`X` = -6752 AND source.`Y` = 824
  AND EXISTS
      (SELECT 1 FROM `quest_poi`
       WHERE `QuestID` = 8306 AND `Idx1` = 1
         AND `ObjectiveIndex` = -1 AND `QuestObjectiveId` = 0
         AND `MapID` = 1 AND `WorldMapAreaId` = 261
         AND `Floor` = 0 AND `Flags` = 1)
  AND NOT EXISTS
      (SELECT 1 FROM `quest_poi_points`
       WHERE `QuestID` = 8306 AND `Idx1` = 1);

COMMIT;
