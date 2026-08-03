-- Exact rollback for
-- 2026_08_03_01_world_disable_removed_prince_sarsarun_lfg.sql.
-- Neither row existed in the active world database before the fix.

DELETE FROM `disables`
WHERE `sourceType` = 13
  AND `entry` IN (299, 310)
  AND `flags` = 0
  AND `params_0` = ''
  AND `params_1` = ''
  AND `comment` = 'Removed Cataclysm pre-launch Elemental Unrest LFG: Prince Sarsarun';
