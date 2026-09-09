-- Universal Hit Rating (31): melee, ranged and spell hit.
-- Replace Parry in occupied stat slot 7; retain the other nine stats.
-- Select Ring A only, neck, historical waist, dagger and all sword variants.
-- Include every current class/spec waist (offset 6) in each VIP armor block.
-- Budget per item: VIP1 900, VIP2 1600, VIP3 3000.
-- Absolute assignments are idempotent. Restart worldserver after applying.

UPDATE `item_template`
   SET `stat_type7` = 31,
       `stat_value7` = CASE
           WHEN `entry` BETWEEN 990000 AND 990031 THEN 900
           WHEN `entry` BETWEEN 990100 AND 990131 THEN 1600
           WHEN `entry` BETWEEN 990200 AND 990231 THEN 3000
       END
 WHERE ((`entry` BETWEEN 990000 AND 990031)
     OR (`entry` BETWEEN 990100 AND 990131)
     OR (`entry` BETWEEN 990200 AND 990231))
   AND (
       (`class` = 4 AND MOD(`entry`, 100) = 1 AND `InventoryType` = 2)
    OR (`class` = 4 AND MOD(`entry`, 100) = 5 AND `InventoryType` = 6)
    OR (`class` = 4 AND MOD(`entry`, 100) = 10 AND `InventoryType` = 11)
    OR (`class` = 2 AND MOD(`entry`, 100) = 17 AND `subclass` = 7 AND `InventoryType` = 13)
    OR (`class` = 2 AND MOD(`entry`, 100) = 20 AND `subclass` = 15 AND `InventoryType` = 13)
    OR (`class` = 2 AND MOD(`entry`, 100) = 24 AND `subclass` = 7 AND `InventoryType` = 22)
    OR (`class` = 2 AND MOD(`entry`, 100) = 26 AND `subclass` = 8 AND `InventoryType` = 17)
   );

UPDATE `item_template`
   SET `stat_type7` = 31,
       `stat_value7` = CASE
           WHEN `entry` BETWEEN 991000 AND 991227 THEN 3000
           WHEN `entry` BETWEEN 992000 AND 992227 THEN 900
           WHEN `entry` BETWEEN 993000 AND 993227 THEN 1600
       END
 WHERE ((`entry` BETWEEN 991000 AND 991227)
     OR (`entry` BETWEEN 992000 AND 992227)
     OR (`entry` BETWEEN 993000 AND 993227))
   AND MOD(`entry`, 10) = 6
   AND `class` = 4 AND `InventoryType` = 6;
