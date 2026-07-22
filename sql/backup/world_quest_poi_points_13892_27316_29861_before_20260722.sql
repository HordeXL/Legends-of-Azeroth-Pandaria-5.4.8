-- Exact rollback for
-- 2026_07_22_02_world_restore_three_quest_poi_points.sql.

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

DELETE FROM `quest_poi_points`
WHERE @quest_poi_backup_ok = 1
  AND
  (
      (`QuestID` = 13892 AND `BlobIndex` = 0 AND `Idx1` = 0
       AND `Idx2` = 0 AND `X` = 4567 AND `Y` = 406)
   OR (`QuestID` = 27316 AND `BlobIndex` = 0 AND `Idx1` = 0
       AND `Idx2` = 0 AND `X` = -5239 AND `Y` = -2340)
   OR (`QuestID` = 29861 AND `BlobIndex` = 0 AND `Idx1` = 0
       AND `Idx2` = 0 AND `X` = 1132 AND `Y` = 31)
  );

INSERT IGNORE INTO `quest_poi_points`
SELECT *
FROM `_backup_quest_poi_points_20260722`
WHERE @quest_poi_backup_ok = 1;

COMMIT;
