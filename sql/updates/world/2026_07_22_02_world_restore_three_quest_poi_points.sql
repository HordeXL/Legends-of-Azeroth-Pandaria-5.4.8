-- Restore three source-backed quest POI points that are missing after the
-- old quest-POI merge/reindex operation.
--
-- Trinity TDB 1200.26021 retains the same POI semantics and coordinates for
-- these three old quests.  The X/Y pairs also already exist in this 5.4.8
-- database under another POI index, so no coordinates are invented here:
--   13892 / POI 0:  4567,  406
--   27316 / POI 0: -5239, -2340
--   29861 / POI 0:  1132,   31
--
-- The other 13 startup warnings in this group are intentionally untouched:
-- their old and current Trinity POI definitions do not provide an exact,
-- semantically matching point for the active 5.4.8 row.

-- CREATE TABLE implicitly commits in MySQL 5.7, so create and populate the
-- persistent exact-row backup before starting the data transaction.
CREATE TABLE IF NOT EXISTS `_backup_quest_poi_points_20260722`
LIKE `quest_poi_points`;

INSERT IGNORE INTO `_backup_quest_poi_points_20260722`
SELECT *
FROM `quest_poi_points`
WHERE (`QuestID` = 13892 AND `BlobIndex` = 2 AND `Idx1` = 1
       AND `Idx2` = 0 AND `X` = 4567 AND `Y` = 406)
   OR (`QuestID` = 27316 AND `BlobIndex` = 1 AND `Idx1` = 1
       AND `Idx2` = 0 AND `X` = -5239 AND `Y` = -2340)
   OR (`QuestID` = 29861 AND `BlobIndex` = 1 AND `Idx1` = 1
       AND `Idx2` = 0 AND `X` = 1190 AND `Y` = 35)
   OR (`QuestID` = 29861 AND `BlobIndex` = 2 AND `Idx1` = 2
       AND `Idx2` = 0 AND `X` = 1132 AND `Y` = 31);

START TRANSACTION;

SET @quest_poi_backup_ok :=
(
    SELECT COUNT(*) = 4
       AND SUM(`QuestID` = 13892 AND `BlobIndex` = 2 AND `Idx1` = 1
               AND `Idx2` = 0 AND `X` = 4567 AND `Y` = 406) = 1
       AND SUM(`QuestID` = 27316 AND `BlobIndex` = 1 AND `Idx1` = 1
               AND `Idx2` = 0 AND `X` = -5239 AND `Y` = -2340) = 1
       AND SUM(`QuestID` = 29861 AND `BlobIndex` = 1 AND `Idx1` = 1
               AND `Idx2` = 0 AND `X` = 1190 AND `Y` = 35) = 1
       AND SUM(`QuestID` = 29861 AND `BlobIndex` = 2 AND `Idx1` = 2
               AND `Idx2` = 0 AND `X` = 1132 AND `Y` = 31) = 1
    FROM `_backup_quest_poi_points_20260722`
);

INSERT IGNORE INTO `quest_poi_points`
    (`QuestID`, `BlobIndex`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 13892, 0, 0, 0, source.`X`, source.`Y`, source.`VerifiedBuild`
FROM `quest_poi_points` source
WHERE @quest_poi_backup_ok = 1
  AND source.`QuestID` = 13892 AND source.`BlobIndex` = 2
  AND source.`Idx1` = 1 AND source.`Idx2` = 0
  AND source.`X` = 4567 AND source.`Y` = 406
  AND EXISTS
      (SELECT 1 FROM `quest_poi`
       WHERE `QuestID` = 13892 AND `Idx1` = 0
         AND `ObjectiveIndex` = 0 AND `QuestObjectiveId` = 266852
         AND `MapID` = 1 AND `WorldMapAreaId` = 42
         AND `Floor` = 0 AND `Flags` = 7)
  AND NOT EXISTS
      (SELECT 1 FROM `quest_poi_points`
       WHERE `QuestID` = 13892 AND `Idx1` = 0);

INSERT IGNORE INTO `quest_poi_points`
    (`QuestID`, `BlobIndex`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 27316, 0, 0, 0, source.`X`, source.`Y`, source.`VerifiedBuild`
FROM `quest_poi_points` source
WHERE @quest_poi_backup_ok = 1
  AND source.`QuestID` = 27316 AND source.`BlobIndex` = 1
  AND source.`Idx1` = 1 AND source.`Idx2` = 0
  AND source.`X` = -5239 AND source.`Y` = -2340
  AND EXISTS
      (SELECT 1 FROM `quest_poi`
       WHERE `QuestID` = 27316 AND `Idx1` = 0
         AND `ObjectiveIndex` = -1 AND `QuestObjectiveId` = 0
         AND `MapID` = 1 AND `WorldMapAreaId` = 61
         AND `Floor` = 0 AND `Flags` = 7)
  AND NOT EXISTS
      (SELECT 1 FROM `quest_poi_points`
       WHERE `QuestID` = 27316 AND `Idx1` = 0);

INSERT IGNORE INTO `quest_poi_points`
    (`QuestID`, `BlobIndex`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 29861, 0, 0, 0, source.`X`, source.`Y`, source.`VerifiedBuild`
FROM `quest_poi_points` source
WHERE @quest_poi_backup_ok = 1
  AND source.`QuestID` = 29861 AND source.`BlobIndex` = 2
  AND source.`Idx1` = 2 AND source.`Idx2` = 0
  AND source.`X` = 1132 AND source.`Y` = 31
  AND EXISTS
      (SELECT 1 FROM `quest_poi`
       WHERE `QuestID` = 29861 AND `Idx1` = 0
         AND `ObjectiveIndex` = -1 AND `QuestObjectiveId` = 0
         AND `MapID` = 602 AND `WorldMapAreaId` = 525
         AND `Floor` = 1 AND `Flags` = 7)
  AND NOT EXISTS
      (SELECT 1 FROM `quest_poi_points`
       WHERE `QuestID` = 29861 AND `Idx1` = 0);

COMMIT;
