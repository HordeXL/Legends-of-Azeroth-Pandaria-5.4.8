-- Exact rollback for the Build-18414 player-create skill repair.
--
-- The forward migration preserves all 36 rejected 4.3.4-era rows in
-- `_backup_playercreateinfo_skills_invalid_20260723`.

DELETE FROM `playercreateinfo_skills`
WHERE (`raceMask`, `classMask`, `skill`) IN
      ((0, 1, 840),
       (0, 8, 921),
       (0, 64, 924),
       (0, 128, 904),
       (0, 256, 849),
       (0, 512, 829));

INSERT INTO `playercreateinfo_skills`
(`raceMask`, `classMask`, `skill`, `rank`, `comment`)
SELECT `raceMask`, `classMask`, `skill`, `rank`, `comment`
FROM `_backup_playercreateinfo_skills_invalid_20260723`
ORDER BY `skill`;
