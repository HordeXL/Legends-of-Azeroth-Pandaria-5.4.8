-- DBC-backed level 80 and level 90 character boosts. The original product 83
-- and its Wasteland equipment remain untouched as a legacy promotion.

DELETE FROM `battle_pay_entry` WHERE `productId` IN (950080, 950090);
DELETE FROM `battle_pay_product_items` WHERE `productId` IN (950080, 950090);
DELETE FROM `battle_pay_product` WHERE `id` IN (950080, 950090);

INSERT INTO `battle_pay_product`
(`id`, `title`, `description`, `icon`, `price`, `discount`, `displayId`, `type`, `choiceType`, `flags`, `flagsInfo`) VALUES
(950080, 'Level 80 Character Boost', 'Boost one eligible character to level 80 with its specialization-specific DBC equipment and level-appropriate training.', 614740, 100, 0, 0, 2, 1, 975, 0),
(950090, 'Level 90 Character Boost', 'Official-style level 90 boost with specialization-specific item level 483 DBC equipment, riding, bags, supplies and training.', 614740, 250, 0, 0, 2, 1, 975, 0);

-- Service products require a representative item in the 5.4.8 StoreUI flow.
INSERT INTO `battle_pay_product_items` (`id`, `itemId`, `count`, `productId`) VALUES
(9500800, 17, 1, 950080),
(9500900, 17, 1, 950090);

INSERT INTO `battle_pay_entry`
(`id`, `productId`, `groupId`, `idx`, `title`, `description`, `icon`, `displayId`, `banner`, `flags`) VALUES
(950080, 950080, 1, 10, '|cff0070ddLevel 80 Character Boost', 'Boosts one character below level 80 to level 80. Includes specialization-specific item level 232 DBC gear, 100 gold, four Frostweave Bags, food, bandages, faction flying mount, Artisan Riding, Northrend and old-world flying, level-appropriate class abilities and weapon skills. The character is moved to Stormwind or Orgrimmar.', 236544, 0, 2, 0),
(950081, 950080, 11, 10, '|cff0070ddLevel 80 Character Boost', 'Boosts one character below level 80 to level 80. Includes specialization-specific item level 232 DBC gear, 100 gold, four Frostweave Bags, food, bandages, faction flying mount, Artisan Riding, Northrend and old-world flying, level-appropriate class abilities and weapon skills. The character is moved to Stormwind or Orgrimmar.', 236544, 0, 2, 0),
(950090, 950090, 1, 11, '|cffff8000Level 90 Character Boost', 'Boosts one character below level 90 to level 90. Includes specialization-specific item level 483 DBC gear, 150 gold, four Embersilk Bags, food, faction flying mount, Artisan Riding, Northrend, old-world and Pandaria flying, and level-appropriate abilities. Existing primary professions and First Aid reach 600 when the character was already level 60 or higher.', 236544, 0, 2, 0),
(950091, 950090, 11, 11, '|cffff8000Level 90 Character Boost', 'Boosts one character below level 90 to level 90. Includes specialization-specific item level 483 DBC gear, 150 gold, four Embersilk Bags, food, faction flying mount, Artisan Riding, Northrend, old-world and Pandaria flying, and level-appropriate abilities. Existing primary professions and First Aid reach 600 when the character was already level 60 or higher.', 236544, 0, 2, 0);
