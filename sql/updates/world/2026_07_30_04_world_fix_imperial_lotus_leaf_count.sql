-- Correct the number of Imperial Lotus Leaves looted per Imperial Lotus.
--
-- Sources:
--   ProjectSkyfire/SkyFire_548 commit
--   3bbe0c44b2694fae697e96259bd27bf9f8584b6d
--   SFDB full 548 release 25.001
--
-- Both matching-version sources use 2-4 leaves. This project retained the
-- older 1-3 count. Preserve the complete old row and change only its counts.

CREATE TABLE IF NOT EXISTS `_backup_gameobject_loot_imperial_lotus_20260730`
LIKE `gameobject_loot_template`;

INSERT INTO `_backup_gameobject_loot_imperial_lotus_20260730`
SELECT `loot`.*
FROM `gameobject_loot_template` AS `loot`
WHERE `loot`.`entry` = 41153
  AND `loot`.`item` = 78918
  AND `loot`.`ChanceOrQuestChance` = -100
  AND `loot`.`lootmode` = ''
  AND `loot`.`groupid` = 0
  AND `loot`.`mincountOrRef` = 1
  AND `loot`.`maxcount` = 3
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_gameobject_loot_imperial_lotus_20260730` AS `backup`
       WHERE `backup`.`entry` = `loot`.`entry`
         AND `backup`.`item` = `loot`.`item`
         AND `backup`.`lootmode` = `loot`.`lootmode`);

START TRANSACTION;

SET @imperial_lotus_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`ChanceOrQuestChance` = -100
               AND `lootmode` = ''
               AND `groupid` = 0
               AND `mincountOrRef` = 1
               AND `maxcount` = 3) = 1
    FROM `_backup_gameobject_loot_imperial_lotus_20260730`
    WHERE `entry` = 41153
      AND `item` = 78918
);

SET @imperial_lotus_dependencies_ok :=
(
    SELECT
        (SELECT COUNT(*)
         FROM `gameobject_template`
         WHERE `entry` = 210209
           AND `type` = 3
           AND `data1` = 41153
           AND `questItem1` = 78918) = 1
        AND
        (SELECT COUNT(*)
         FROM `item_template`
         WHERE `entry` = 78918
           AND `name` = 'Imperial Lotus Leaves') = 1
        AND
        (SELECT COUNT(*)
         FROM `quest_objective`
         WHERE `questId` IN (30130, 30351)
           AND `type` = 1
           AND `objectId` = 78918
           AND `amount` = 20) = 2
);

UPDATE `gameobject_loot_template`
SET
    `mincountOrRef` = 2,
    `maxcount` = 4
WHERE @imperial_lotus_backup_ok = 1
  AND @imperial_lotus_dependencies_ok = 1
  AND `entry` = 41153
  AND `item` = 78918
  AND `ChanceOrQuestChance` = -100
  AND `lootmode` = ''
  AND `groupid` = 0
  AND `mincountOrRef` = 1
  AND `maxcount` = 3;

COMMIT;
