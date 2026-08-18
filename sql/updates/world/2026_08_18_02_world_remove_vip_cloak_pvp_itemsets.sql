-- VIP1/VIP2/VIP3 cloaks were historically assigned the same PvP ItemSet as
-- the armor pieces. Cloaks are not members of those five-piece sets and must
-- not display or contribute to their set bonus.
-- Preserve item IDs, ownership, stats, display and vendor links; clear only the
-- incorrect ItemSet relationship, guarded by the three exact legacy values.

UPDATE `item_template`
   SET `itemset` = 0
 WHERE (`entry` = 990014 AND `InventoryType` = 16 AND `itemset` = 1117)
    OR (`entry` = 990114 AND `InventoryType` = 16 AND `itemset` = 1119)
    OR (`entry` = 990214 AND `InventoryType` = 16 AND `itemset` = 1111);

-- Expected: all three VIP cloaks remain present and none has an ItemSet.
SELECT COUNT(*) AS `vip_cloaks_without_itemset`
  FROM `item_template`
 WHERE `entry` IN (990014,990114,990214)
   AND `InventoryType` = 16
   AND `itemset` = 0;
