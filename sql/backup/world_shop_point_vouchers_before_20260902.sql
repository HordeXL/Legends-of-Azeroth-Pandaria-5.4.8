-- Roll back sql/updates/world/2026_09_02_02_world_shop_point_vouchers.sql.

UPDATE `battle_pay_product`
SET `title` = CASE `id`
        WHEN 1 THEN 'Shop: WoW Token - 01'
        WHEN 2 THEN 'Shop: WoW Token - 02'
        WHEN 3 THEN 'Shop: WoW Token - 05'
        WHEN 4 THEN 'Shop: WoW Token - 10'
    END,
    `description` = CASE `id`
        WHEN 1 THEN '01 point for the Pandaria-WoW shop'
        WHEN 2 THEN '02 point for the Pandaria-WoW shop'
        WHEN 3 THEN '05 point for the Pandaria-WoW shop'
        WHEN 4 THEN '10 point for the Pandaria-WoW shop'
    END
WHERE `id` IN (1, 2, 3, 4);

UPDATE `item_template`
SET `name` = CASE `entry`
        WHEN 110001 THEN 'Pandaria-Coins 01'
        WHEN 110002 THEN 'Pandaria-Coins 02'
        WHEN 110003 THEN 'Pandaria-Coins 05'
        WHEN 110004 THEN 'Pandaria-Coins 10'
    END,
    `description` = CASE `entry`
        WHEN 110001 THEN 'Ever since Saitamapaz fell mad, and went bald, he has been searching for every single one of his hairs around the world. You got a handful of them, will you dare to return it? (value: 01 Athenas Coins).'
        WHEN 110002 THEN 'Ever since Saitamapaz fell mad, and went bald, he has been searching for every single one of his hairs around the world. You got a handful of them, will you dare to return it? (value: 02 Athenas Coins).'
        WHEN 110003 THEN 'Ever since Saitamapaz fell mad, and went bald, he has been searching for every single one of his hairs around the world. You got a handful of them, will you dare to return it? (value: 05 Athenas Coins).'
        WHEN 110004 THEN 'Ever since Saitamapaz fell mad, and went bald, he has been searching for every single one of his hairs around the world. You got a handful of them, will you dare to return it? (value: 10 Athenas Coins).'
    END,
    `bonding` = 0
WHERE `entry` IN (110001, 110002, 110003, 110004);

UPDATE `trinity_string`
SET `content_default` = 'Thanks for helping the Pandaria 5.4.8 project, you just received donate coins: %f'
WHERE `entry` = 30007;
