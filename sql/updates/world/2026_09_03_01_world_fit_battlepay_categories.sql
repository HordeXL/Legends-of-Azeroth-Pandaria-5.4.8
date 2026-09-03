-- Keep the complete BattlePay catalog accessible in the stock 5.4.8 StoreUI.
-- It has ten visible category buttons and cannot safely be overridden with a
-- loose modified Blizzard_StoreUI file because that addon is secure/signed.
-- Merge related categories so all products fit without client modifications.

START TRANSACTION;

-- Gold products and point/currency products share one category.
UPDATE `battle_pay_entry` SET `groupId` = 9 WHERE `groupId` = 10;
UPDATE `battle_pay_group`
   SET `idx` = 6, `name` = 'Gold & Currency'
 WHERE `id` = 9;

-- Both Pandaria raid equipment catalogs share one category.
UPDATE `battle_pay_entry` SET `groupId` = 13 WHERE `groupId` = 14;
UPDATE `battle_pay_group`
   SET `idx` = 8, `name` = 'Pandaria Raids'
 WHERE `id` = 13;

-- VIP1, VIP2 and VIP3 armor entries share one category. Entry titles retain
-- their VIP rank, class and specialization, so the tiers remain unambiguous.
UPDATE `battle_pay_entry` SET `groupId` = 20 WHERE `groupId` IN (21, 22);
UPDATE `battle_pay_group`
   SET `idx` = 9, `name` = 'VIP 1-3 SETS'
 WHERE `id` = 20;
UPDATE `battle_pay_group`
   SET `idx` = 10, `name` = 'VIP 1-3 WEAPONS'
 WHERE `id` = 23;

-- Compact the remaining visible categories into positions 1-10.
UPDATE `battle_pay_group` SET `idx` = 1 WHERE `id` = 1;
UPDATE `battle_pay_group` SET `idx` = 2 WHERE `id` = 2;
UPDATE `battle_pay_group` SET `idx` = 3 WHERE `id` = 3;
UPDATE `battle_pay_group` SET `idx` = 4 WHERE `id` = 4;
UPDATE `battle_pay_group` SET `idx` = 5 WHERE `id` = 7;
UPDATE `battle_pay_group` SET `idx` = 7 WHERE `id` = 11;

DELETE FROM `locales_battle_pay_group` WHERE `id` IN (10, 14, 21, 22);
DELETE FROM `battle_pay_group` WHERE `id` IN (10, 14, 21, 22);

COMMIT;

-- Expected: ten groups with products, including both VIP categories.
SELECT g.`id`, g.`idx`, g.`name`, COUNT(e.`id`) AS `entries`
  FROM `battle_pay_group` g
  JOIN `battle_pay_entry` e ON e.`groupId` = g.`id`
 GROUP BY g.`id`, g.`idx`, g.`name`
 ORDER BY g.`idx`, g.`id`;
