-- Make the BattlePay token products lossless, tradeable shop-point vouchers.
-- Their redemption value matches the exact price paid in the shop.

UPDATE `battle_pay_product`
SET `title` = CASE `id`
        WHEN 1 THEN 'Shop: Shop Points Voucher - 2'
        WHEN 2 THEN 'Shop: Shop Points Voucher - 3'
        WHEN 3 THEN 'Shop: Shop Points Voucher - 7'
        WHEN 4 THEN 'Shop: Shop Points Voucher - 13'
    END,
    `description` = CASE `id`
        WHEN 1 THEN 'Tradeable voucher. Use it to add 2 shop points to the recipient account.'
        WHEN 2 THEN 'Tradeable voucher. Use it to add 3 shop points to the recipient account.'
        WHEN 3 THEN 'Tradeable voucher. Use it to add 7 shop points to the recipient account.'
        WHEN 4 THEN 'Tradeable voucher. Use it to add 13 shop points to the recipient account.'
    END
WHERE `id` IN (1, 2, 3, 4);

UPDATE `item_template`
SET `name` = CASE `entry`
        WHEN 110001 THEN 'Shop Points Voucher - 2'
        WHEN 110002 THEN 'Shop Points Voucher - 3'
        WHEN 110003 THEN 'Shop Points Voucher - 7'
        WHEN 110004 THEN 'Shop Points Voucher - 13'
    END,
    `description` = CASE `entry`
        WHEN 110001 THEN 'Trade this voucher or use it to add 2 shop points to your account.'
        WHEN 110002 THEN 'Trade this voucher or use it to add 3 shop points to your account.'
        WHEN 110003 THEN 'Trade this voucher or use it to add 7 shop points to your account.'
        WHEN 110004 THEN 'Trade this voucher or use it to add 13 shop points to your account.'
    END,
    `bonding` = 0
WHERE `entry` IN (110001, 110002, 110003, 110004);

UPDATE `trinity_string`
SET `content_default` = 'Shop points voucher redeemed: %u points were added to your account.'
WHERE `entry` = 30007;
