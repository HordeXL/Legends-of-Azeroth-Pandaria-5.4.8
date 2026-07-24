-- Spell 67789 is a Cataclysm-era zone phasing spell used by quest 14293 and
-- Wandering Isle scripts in this 5.4.8 database.
--
-- These two spell_area rows instead reference quests 40328 and 40329, neither
-- of which exists in the 5.4.8 quest_template. No independent 5.4.8
-- SkyFire/Trinity source contains these links. The loader already rejects both
-- rows, so removing the exact invalid records cannot remove active behavior.

CREATE TABLE IF NOT EXISTS `_backup_spell_area_67789_20260723` LIKE `spell_area`;

INSERT IGNORE INTO `_backup_spell_area_67789_20260723`
SELECT *
FROM `spell_area`
WHERE (`spell`, `area`, `quest_start`, `quest_end`, `aura_spell`, `racemask`,
       `gender`, `autocast`, `quest_start_status`, `quest_end_status`) IN
      ((67789, 6484, 40328, 0, 0, 0, 2, 1, 8, 1),
       (67789, 6519, 40329, 0, 0, 0, 2, 1, 8, 1));

DELETE `sa`
FROM `spell_area` AS `sa`
LEFT JOIN `quest_template` AS `q`
  ON `q`.`Id` = `sa`.`quest_start`
WHERE (`sa`.`spell`, `sa`.`area`, `sa`.`quest_start`, `sa`.`quest_end`,
       `sa`.`aura_spell`, `sa`.`racemask`, `sa`.`gender`, `sa`.`autocast`,
       `sa`.`quest_start_status`, `sa`.`quest_end_status`) IN
      ((67789, 6484, 40328, 0, 0, 0, 2, 1, 8, 1),
       (67789, 6519, 40329, 0, 0, 0, 2, 1, 8, 1))
  AND `q`.`Id` IS NULL;
