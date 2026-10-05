-- Make Winterfin Clams activate and sparkle for players collecting item 34597
-- for quest 11559, Winterfin Commerce.

CREATE TABLE IF NOT EXISTS `_backup_gameobject_template_winterfin_clam_20260929`
LIKE `gameobject_template`;

INSERT INTO `_backup_gameobject_template_winterfin_clam_20260929`
SELECT `got`.*
FROM `gameobject_template` AS `got`
WHERE `got`.`entry` = 187367
  AND NOT EXISTS
  (
      SELECT 1
      FROM `_backup_gameobject_template_winterfin_clam_20260929` AS `b`
      WHERE `b`.`entry` = `got`.`entry`
  );

CREATE TABLE IF NOT EXISTS `_backup_gameobject_loot_winterfin_clam_20260929`
LIKE `gameobject_loot_template`;

INSERT INTO `_backup_gameobject_loot_winterfin_clam_20260929`
SELECT `glt`.*
FROM `gameobject_loot_template` AS `glt`
WHERE `glt`.`entry` = 187367
  AND `glt`.`item` = 34597
  AND NOT EXISTS
  (
      SELECT 1
      FROM `_backup_gameobject_loot_winterfin_clam_20260929` AS `b`
      WHERE `b`.`entry` = `glt`.`entry`
        AND `b`.`item` = `glt`.`item`
  );

UPDATE `gameobject_template`
SET `questItem1` = 34597
WHERE `entry` = 187367;

UPDATE `gameobject_loot_template`
SET `ChanceOrQuestChance` = -ABS(`ChanceOrQuestChance`)
WHERE `entry` = 187367
  AND `item` = 34597;
