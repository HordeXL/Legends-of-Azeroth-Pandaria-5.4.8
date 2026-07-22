-- Rollback for
-- 2026_07_22_01_world_remove_cross_version_quest_objectives.sql.
--
-- Restores the exact three rows from the persistent backup table.  This also
-- restores the original startup warnings and later-version quest behavior;
-- it is provided only as an exact rollback path.

START TRANSACTION;

SET @cross_version_quest_objective_backup_ok :=
(
    SELECT COUNT(*) = 3
       AND SUM(`questId` = 10794 AND `id` = 273866 AND `objectId` = 113135) = 1
       AND SUM(`questId` = 11997 AND `id` = 280563 AND `objectId` = 99418) = 1
       AND SUM(`questId` = 11997 AND `id` = 280564 AND `objectId` = 100290) = 1
    FROM `_backup_quest_objective_cross_version_20260722`
);

INSERT IGNORE INTO `quest_objective`
SELECT *
FROM `_backup_quest_objective_cross_version_20260722`
WHERE @cross_version_quest_objective_backup_ok = 1;

COMMIT;
