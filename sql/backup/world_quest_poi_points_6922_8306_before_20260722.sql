-- Exact rollback for
-- 2026_07_22_03_world_restore_two_legacy_quest_poi_points.sql.

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

DELETE FROM `quest_poi_points`
WHERE @quest_poi_6922_8306_backup_ok = 1
  AND
  (
      (`QuestID` = 6922 AND `BlobIndex` = 0 AND `Idx1` = 1
       AND `Idx2` = 0 AND `X` = 3355 AND `Y` = 1033)
   OR (`QuestID` = 8306 AND `BlobIndex` = 0 AND `Idx1` = 1
       AND `Idx2` = 0 AND `X` = -6752 AND `Y` = 824)
  );

INSERT IGNORE INTO `quest_poi_points`
SELECT *
FROM `_backup_quest_poi_points_6922_8306_20260722`
WHERE @quest_poi_6922_8306_backup_ok = 1;

COMMIT;
