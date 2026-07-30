-- Exact rollback for
-- 2026_07_30_04_world_fix_imperial_lotus_leaf_count.sql.
--
-- Restore the complete captured row only while the active row still matches
-- the exact 2-4 state installed by that migration.

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

UPDATE `gameobject_loot_template` AS `target`
INNER JOIN `_backup_gameobject_loot_imperial_lotus_20260730` AS `backup`
    ON `backup`.`entry` = `target`.`entry`
   AND `backup`.`item` = `target`.`item`
   AND `backup`.`lootmode` = `target`.`lootmode`
SET
    `target`.`ChanceOrQuestChance` = `backup`.`ChanceOrQuestChance`,
    `target`.`groupid` = `backup`.`groupid`,
    `target`.`mincountOrRef` = `backup`.`mincountOrRef`,
    `target`.`maxcount` = `backup`.`maxcount`
WHERE @imperial_lotus_backup_ok = 1
  AND `target`.`entry` = 41153
  AND `target`.`item` = 78918
  AND `target`.`ChanceOrQuestChance` = -100
  AND `target`.`lootmode` = ''
  AND `target`.`groupid` = 0
  AND `target`.`mincountOrRef` = 2
  AND `target`.`maxcount` = 4;

COMMIT;
