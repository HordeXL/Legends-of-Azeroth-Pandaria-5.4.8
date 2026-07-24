-- Exact rollback for the two invalid spell_area rows removed on 2026-07-23.
--
-- Both rows are also preserved automatically in
-- `_backup_spell_area_67789_20260723` by the forward migration.

DELETE FROM `spell_area`
WHERE (`spell`, `area`, `quest_start`, `quest_end`, `aura_spell`, `racemask`,
       `gender`, `autocast`, `quest_start_status`, `quest_end_status`) IN
      ((67789, 6484, 40328, 0, 0, 0, 2, 1, 8, 1),
       (67789, 6519, 40329, 0, 0, 0, 2, 1, 8, 1));

INSERT INTO `spell_area`
(`spell`, `area`, `quest_start`, `quest_end`, `aura_spell`, `racemask`,
 `gender`, `autocast`, `quest_start_status`, `quest_end_status`)
VALUES
(67789, 6484, 40328, 0, 0, 0, 2, 1, 8, 1),
(67789, 6519, 40329, 0, 0, 0, 2, 1, 8, 1);
