-- Restore exact loot rows from matching-version SkyFire 5.4.8 SFDB full
-- release 24.001. Existing loot rows are never replaced or deleted.
-- Galleon entry 62346 is intentionally excluded: the matching final source
-- contains no ordinary creature_loot_template rows for that entry.

START TRANSACTION;

INSERT INTO `creature_loot_template`
    (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`)
SELECT 60491, 89317, -5.47213, 1, 0, 1, 1
WHERE EXISTS
      (SELECT 1 FROM `creature_template`
       WHERE `entry` = 60491 AND `lootid` = 60491)
  AND EXISTS
      (SELECT 1 FROM `item_template` WHERE `entry` = 89317)
  AND NOT EXISTS
      (SELECT 1 FROM `creature_loot_template`
       WHERE `entry` = 60491 AND `item` = 89317 AND `lootmode` = 1);

INSERT INTO `gameobject_loot_template`
    (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`)
SELECT src.`entry`, src.`item`, src.`chance`, 1, 0, 1, src.`maxcount`
FROM
(
    SELECT 218197 AS `entry`, 93962 AS `item`, 100.0 AS `chance`, 1 AS `maxcount`
    UNION ALL SELECT 218577, 46109, 16.67, 1
    UNION ALL SELECT 218577, 74857, 6.67, 1
    UNION ALL SELECT 218577, 86545, 6.67, 1
    UNION ALL SELECT 218577, 88496, 6.67, 1
    UNION ALL SELECT 218577, 94935, 16.67, 1
    UNION ALL SELECT 218577, 97981, 16.67, 1
    UNION ALL SELECT 220196, 81205, 19.24, 6
    UNION ALL SELECT 220196, 82011, 0.11, 1
    UNION ALL SELECT 220196, 82121, 0.11, 1
    UNION ALL SELECT 220196, 82126, 2.59, 1
    UNION ALL SELECT 220196, 82157, 0.54, 1
    UNION ALL SELECT 220196, 82208, 0.11, 1
    UNION ALL SELECT 220196, 82285, 0.11, 1
    UNION ALL SELECT 221776, 87282, -44.11, 1
    UNION ALL SELECT 221776, 87389, -40.98, 1
) AS src
INNER JOIN `gameobject_template` AS go
        ON go.`entry` = src.`entry` AND go.`data1` = src.`entry`
INNER JOIN `item_template` AS item
        ON item.`entry` = src.`item`
WHERE NOT EXISTS
      (SELECT 1 FROM `gameobject_loot_template` AS existing
       WHERE existing.`entry` = src.`entry`
         AND existing.`item` = src.`item`
         AND existing.`lootmode` = 1);

COMMIT;
