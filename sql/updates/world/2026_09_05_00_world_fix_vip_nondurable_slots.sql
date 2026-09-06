-- VIP accessories inherited MaxDurability=255 from the universal template.
-- Neck, shirt, ring, trinket, cloak, tabard, robe and held-in-offhand items are
-- non-durable inventory types in this client and must never become broken.
-- Weapons, shields and actual armor pieces intentionally retain durability.

UPDATE `item_template`
   SET `MaxDurability` = 0
 WHERE `entry` BETWEEN 990000 AND 999999
   AND `InventoryType` IN (2, 4, 11, 12, 16, 19, 20, 23)
   AND `MaxDurability` <> 0;

-- Expected: no custom VIP non-durable template keeps durability.
SELECT COUNT(*) AS `vip_nondurable_items_with_durability`
  FROM `item_template`
 WHERE `entry` BETWEEN 990000 AND 999999
   AND `InventoryType` IN (2, 4, 11, 12, 16, 19, 20, 23)
   AND `MaxDurability` <> 0;
