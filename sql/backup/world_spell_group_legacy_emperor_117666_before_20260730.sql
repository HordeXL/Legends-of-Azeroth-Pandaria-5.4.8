-- Exact rollback for
-- 2026_07_30_03_world_fix_legacy_emperor_raid_aura_spell_group.sql.
--
-- The active migration only adds spell 117666 to group 1149. This rollback
-- removes that exact added row only when the preserved pre-update group and
-- the complete expected post-update group are both present.

START TRANSACTION;

SET @legacy_emperor_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`spell_id` = 117667
               AND `comment` = 'Legacy of the Emperor') = 1
    FROM `_backup_spell_group_legacy_emperor_20260730`
    WHERE `id` = 1149
);

SET @legacy_emperor_live_ok :=
(
    SELECT COUNT(*) = 2
       AND SUM(`spell_id` = 117666
               AND `comment` = 'Legacy of the Emperor') = 1
       AND SUM(`spell_id` = 117667
               AND `comment` = 'Legacy of the Emperor') = 1
    FROM `spell_group`
    WHERE `id` = 1149
);

DELETE FROM `spell_group`
WHERE @legacy_emperor_backup_ok = 1
  AND @legacy_emperor_live_ok = 1
  AND `id` = 1149
  AND `spell_id` = 117666
  AND `comment` = 'Legacy of the Emperor';

COMMIT;
