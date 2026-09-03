-- Add the custom VIP1/VIP2/VIP3 PvE armor to the in-game BattlePay shop.
--
-- The stock 5.4.8 StoreUI supports only one category level and ten visible
-- category buttons. All three armor ranks therefore share one VIP category,
-- while weapons remain in a separate category. The VIP prefix in every entry
-- keeps ranks distinct. The core filters armor products to the logged-in
-- character's class. Every armor block has one discounted eight-piece bundle
-- and all eight pieces available separately. Weapons are never bundled.
--
-- Product/entry IDs:
--   VIP1 armor 910000-910228
--   VIP2 armor 920000-920228
--   VIP3 armor 930000-930228
--   VIP weapons 940000-940214 (three 15-entry blocks)

SET @VIP_SHOP_OLD_SQL_SAFE_UPDATES := @@SQL_SAFE_UPDATES;
SET SQL_SAFE_UPDATES = 0;

DELETE FROM `battle_pay_product_items`
 WHERE (`productId` BETWEEN 910000 AND 910228)
    OR (`productId` BETWEEN 920000 AND 920228)
    OR (`productId` BETWEEN 930000 AND 930228)
    OR (`productId` BETWEEN 940000 AND 940014)
    OR (`productId` BETWEEN 940100 AND 940114)
    OR (`productId` BETWEEN 940200 AND 940214);

DELETE FROM `battle_pay_entry`
 WHERE (`productId` BETWEEN 910000 AND 910228)
    OR (`productId` BETWEEN 920000 AND 920228)
    OR (`productId` BETWEEN 930000 AND 930228)
    OR (`productId` BETWEEN 940000 AND 940014)
    OR (`productId` BETWEEN 940100 AND 940114)
    OR (`productId` BETWEEN 940200 AND 940214);

DELETE FROM `battle_pay_product`
 WHERE (`id` BETWEEN 910000 AND 910228)
    OR (`id` BETWEEN 920000 AND 920228)
    OR (`id` BETWEEN 930000 AND 930228)
    OR (`id` BETWEEN 940000 AND 940014)
    OR (`id` BETWEEN 940100 AND 940114)
    OR (`id` BETWEEN 940200 AND 940214);

DELETE FROM `battle_pay_group` WHERE `id` BETWEEN 20 AND 23;
INSERT INTO `battle_pay_group` (`id`,`idx`,`name`,`icon`,`type`) VALUES
    (20,9,'VIP 1-3 SETS',940856,0),
    (23,10,'VIP 1-3 WEAPONS',940868,0);

DELIMITER $$

DROP PROCEDURE IF EXISTS `shop_vip_add_set`$$
CREATE PROCEDURE `shop_vip_add_set`(
    IN p_rank TINYINT UNSIGNED,
    IN p_block TINYINT UNSIGNED,
    IN p_class_label VARCHAR(16),
    IN p_spec_label VARCHAR(20)
)
BEGIN
    DECLARE v_item_base INT UNSIGNED;
    DECLARE v_product_base INT UNSIGNED;
    DECLARE v_group INT UNSIGNED;
    DECLARE v_bundle_price INT UNSIGNED;
    DECLARE v_piece_price INT UNSIGNED;
    DECLARE v_full_product INT UNSIGNED;
    DECLARE v_piece_product INT UNSIGNED;
    DECLARE v_item INT UNSIGNED;
    DECLARE v_offset TINYINT UNSIGNED DEFAULT 0;
    DECLARE v_title VARCHAR(55);
    DECLARE v_description VARCHAR(500);
    DECLARE v_slot_label VARCHAR(12);

    SET v_item_base = CASE p_rank WHEN 1 THEN 992000 WHEN 2 THEN 993000 ELSE 991000 END;
    SET v_product_base = CASE p_rank WHEN 1 THEN 910000 WHEN 2 THEN 920000 ELSE 930000 END;
    SET v_group = 20;
    SET v_bundle_price = CASE p_rank WHEN 1 THEN 30 WHEN 2 THEN 60 ELSE 120 END;
    SET v_piece_price = CASE p_rank WHEN 1 THEN 5 WHEN 2 THEN 10 ELSE 20 END;
    SET v_full_product = v_product_base + (p_block * 10);
    SET v_title = CONCAT('VIP', p_rank, ' ', p_class_label, ' ', p_spec_label, ' Full Set');
    SET v_description = CONCAT(
        'Complete 8-piece VIP', p_rank, ' ', p_class_label, ' ', p_spec_label,
        ' PvE armor set: head, shoulders, chest, legs, hands, feet, waist and wrists. Weapons are not included.');

    INSERT INTO `battle_pay_product`
        (`id`,`title`,`description`,`icon`,`price`,`discount`,`displayId`,`type`,`choiceType`,`flags`,`flagsInfo`)
    VALUES
        (v_full_product,v_title,v_description,940856,v_bundle_price,0,0,0,1,46,0);
    INSERT INTO `battle_pay_entry`
        (`id`,`productId`,`groupId`,`idx`,`title`,`description`,`icon`,`displayId`,`banner`,`flags`)
    VALUES
        (v_full_product,v_full_product,v_group,p_block*10,v_title,v_description,0,0,0,0);

    SET v_offset = 0;
    WHILE v_offset < 8 DO
        SET v_item = v_item_base + (p_block * 10) + v_offset;
        IF NOT EXISTS (SELECT 1 FROM `item_template` WHERE `entry` = v_item) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'VIP shop armor source item is missing';
        END IF;

        INSERT INTO `battle_pay_product_items` (`id`,`itemId`,`count`,`productId`)
        VALUES ((v_full_product * 10) + v_offset,v_item,1,v_full_product);

        SET v_slot_label = CASE v_offset
            WHEN 0 THEN 'Head'
            WHEN 1 THEN 'Shoulders'
            WHEN 2 THEN 'Chest'
            WHEN 3 THEN 'Legs'
            WHEN 4 THEN 'Hands'
            WHEN 5 THEN 'Feet'
            WHEN 6 THEN 'Waist'
            ELSE 'Wrists'
        END;
        SET v_piece_product = v_full_product + v_offset + 1;
        SET v_title = CONCAT('VIP', p_rank, ' ', p_class_label, ' ', p_spec_label, ' ', v_slot_label);
        SET v_description = CONCAT(
            'Single VIP', p_rank, ' ', p_class_label, ' ', p_spec_label,
            ' PvE armor piece. The discounted full armor set is also available in this category.');

        INSERT INTO `battle_pay_product`
            (`id`,`title`,`description`,`icon`,`price`,`discount`,`displayId`,`type`,`choiceType`,`flags`,`flagsInfo`)
        VALUES
            (v_piece_product,v_title,v_description,940856,v_piece_price,0,0,0,1,46,0);
        INSERT INTO `battle_pay_product_items` (`id`,`itemId`,`count`,`productId`)
        VALUES (v_piece_product*10,v_item,1,v_piece_product);
        INSERT INTO `battle_pay_entry`
            (`id`,`productId`,`groupId`,`idx`,`title`,`description`,`icon`,`displayId`,`banner`,`flags`)
        VALUES
            (v_piece_product,v_piece_product,v_group,(p_block*10)+v_offset+1,v_title,v_description,0,0,0,0);

        SET v_offset = v_offset + 1;
    END WHILE;
END$$

-- VIP1 / T14.
CALL `shop_vip_add_set`(1, 0,'Death Knight','Frost-Unholy DPS')$$
CALL `shop_vip_add_set`(1, 1,'Death Knight','Blood Tank')$$
CALL `shop_vip_add_set`(1, 2,'Druid','Restoration Heal')$$
CALL `shop_vip_add_set`(1, 3,'Druid','Balance DPS')$$
CALL `shop_vip_add_set`(1, 4,'Druid','Feral DPS')$$
CALL `shop_vip_add_set`(1, 5,'Druid','Guardian Tank')$$
CALL `shop_vip_add_set`(1, 6,'Hunter','DPS')$$
CALL `shop_vip_add_set`(1, 7,'Mage','DPS')$$
CALL `shop_vip_add_set`(1, 8,'Monk','Mistweaver Heal')$$
CALL `shop_vip_add_set`(1, 9,'Monk','Windwalker DPS')$$
CALL `shop_vip_add_set`(1,10,'Monk','Brewmaster Tank')$$
CALL `shop_vip_add_set`(1,11,'Paladin','Holy Heal')$$
CALL `shop_vip_add_set`(1,12,'Paladin','Retribution DPS')$$
CALL `shop_vip_add_set`(1,13,'Paladin','Protection Tank')$$
CALL `shop_vip_add_set`(1,14,'Priest','Discipline-Holy Heal')$$
CALL `shop_vip_add_set`(1,15,'Priest','Shadow DPS')$$
CALL `shop_vip_add_set`(1,16,'Rogue','DPS')$$
CALL `shop_vip_add_set`(1,17,'Shaman','Restoration Heal')$$
CALL `shop_vip_add_set`(1,18,'Shaman','Elemental DPS')$$
CALL `shop_vip_add_set`(1,19,'Shaman','Enhancement DPS')$$
CALL `shop_vip_add_set`(1,20,'Warlock','DPS')$$
CALL `shop_vip_add_set`(1,21,'Warrior','Arms-Fury DPS')$$
CALL `shop_vip_add_set`(1,22,'Warrior','Protection Tank')$$

-- VIP2 / T15.
CALL `shop_vip_add_set`(2, 0,'Death Knight','Blood Tank')$$
CALL `shop_vip_add_set`(2, 1,'Death Knight','Frost-Unholy DPS')$$
CALL `shop_vip_add_set`(2, 2,'Druid','Feral DPS')$$
CALL `shop_vip_add_set`(2, 3,'Druid','Restoration Heal')$$
CALL `shop_vip_add_set`(2, 4,'Druid','Balance DPS')$$
CALL `shop_vip_add_set`(2, 5,'Druid','Guardian Tank')$$
CALL `shop_vip_add_set`(2, 6,'Hunter','DPS')$$
CALL `shop_vip_add_set`(2, 7,'Mage','DPS')$$
CALL `shop_vip_add_set`(2, 8,'Monk','Windwalker DPS')$$
CALL `shop_vip_add_set`(2, 9,'Monk','Mistweaver Heal')$$
CALL `shop_vip_add_set`(2,10,'Monk','Brewmaster Tank')$$
CALL `shop_vip_add_set`(2,11,'Paladin','Retribution DPS')$$
CALL `shop_vip_add_set`(2,12,'Paladin','Holy Heal')$$
CALL `shop_vip_add_set`(2,13,'Paladin','Protection Tank')$$
CALL `shop_vip_add_set`(2,14,'Priest','Discipline-Holy Heal')$$
CALL `shop_vip_add_set`(2,15,'Priest','Shadow DPS')$$
CALL `shop_vip_add_set`(2,16,'Rogue','DPS')$$
CALL `shop_vip_add_set`(2,17,'Shaman','Restoration Heal')$$
CALL `shop_vip_add_set`(2,18,'Shaman','Enhancement DPS')$$
CALL `shop_vip_add_set`(2,19,'Shaman','Elemental DPS')$$
CALL `shop_vip_add_set`(2,20,'Warlock','DPS')$$
CALL `shop_vip_add_set`(2,21,'Warrior','Arms-Fury DPS')$$
CALL `shop_vip_add_set`(2,22,'Warrior','Protection Tank')$$

-- VIP3 / T16.
CALL `shop_vip_add_set`(3, 0,'Warrior','Protection Tank')$$
CALL `shop_vip_add_set`(3, 1,'Warrior','Arms-Fury DPS')$$
CALL `shop_vip_add_set`(3, 2,'Warlock','DPS')$$
CALL `shop_vip_add_set`(3, 3,'Shaman','Elemental DPS')$$
CALL `shop_vip_add_set`(3, 4,'Shaman','Enhancement DPS')$$
CALL `shop_vip_add_set`(3, 5,'Shaman','Restoration Heal')$$
CALL `shop_vip_add_set`(3, 6,'Rogue','DPS')$$
CALL `shop_vip_add_set`(3, 7,'Priest','Shadow DPS')$$
CALL `shop_vip_add_set`(3, 8,'Priest','Discipline-Holy Heal')$$
CALL `shop_vip_add_set`(3, 9,'Paladin','Protection Tank')$$
CALL `shop_vip_add_set`(3,10,'Paladin','Holy Heal')$$
CALL `shop_vip_add_set`(3,11,'Paladin','Retribution DPS')$$
CALL `shop_vip_add_set`(3,12,'Monk','Brewmaster Tank')$$
CALL `shop_vip_add_set`(3,13,'Monk','Mistweaver Heal')$$
CALL `shop_vip_add_set`(3,14,'Monk','Windwalker DPS')$$
CALL `shop_vip_add_set`(3,15,'Mage','DPS')$$
CALL `shop_vip_add_set`(3,16,'Hunter','DPS')$$
CALL `shop_vip_add_set`(3,17,'Druid','Feral DPS')$$
CALL `shop_vip_add_set`(3,18,'Druid','Balance DPS')$$
CALL `shop_vip_add_set`(3,19,'Druid','Restoration Heal')$$
CALL `shop_vip_add_set`(3,20,'Druid','Guardian Tank')$$
CALL `shop_vip_add_set`(3,21,'Death Knight','Frost-Unholy DPS')$$
CALL `shop_vip_add_set`(3,22,'Death Knight','Blood Tank')$$

DROP PROCEDURE IF EXISTS `shop_vip_add_weapons`$$
CREATE PROCEDURE `shop_vip_add_weapons`()
BEGIN
    DECLARE v_rank TINYINT UNSIGNED DEFAULT 1;
    DECLARE v_offset TINYINT UNSIGNED;
    DECLARE v_item INT UNSIGNED;
    DECLARE v_product INT UNSIGNED;
    DECLARE v_price INT UNSIGNED;
    DECLARE v_title VARCHAR(55);
    DECLARE v_description VARCHAR(500);

    WHILE v_rank <= 3 DO
        SET v_offset = 0;
        SET v_price = CASE v_rank WHEN 1 THEN 10 WHEN 2 THEN 20 ELSE 40 END;
        WHILE v_offset < 15 DO
            SET v_item = 990017 + ((v_rank - 1) * 100) + v_offset;
            SET v_product = 940000 + ((v_rank - 1) * 100) + v_offset;
            SELECT `name` INTO v_title FROM `item_template` WHERE `entry` = v_item LIMIT 1;
            IF v_title IS NULL THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'VIP shop weapon source item is missing';
            END IF;
            SET v_description = CONCAT(
                'VIP', v_rank, ' PvE weapon sold separately. Choose the weapon and off-hand combination required by your specialization.');

            INSERT INTO `battle_pay_product`
                (`id`,`title`,`description`,`icon`,`price`,`discount`,`displayId`,`type`,`choiceType`,`flags`,`flagsInfo`)
            VALUES
                (v_product,LEFT(v_title,50),v_description,940868,v_price,0,0,0,1,46,0);
            INSERT INTO `battle_pay_product_items` (`id`,`itemId`,`count`,`productId`)
            VALUES (v_product*10,v_item,1,v_product);
            INSERT INTO `battle_pay_entry`
                (`id`,`productId`,`groupId`,`idx`,`title`,`description`,`icon`,`displayId`,`banner`,`flags`)
            VALUES
                (v_product,v_product,23,((v_rank-1)*100)+v_offset,LEFT(v_title,55),v_description,0,0,0,0);

            SET v_offset = v_offset + 1;
        END WHILE;
        SET v_rank = v_rank + 1;
    END WHILE;
END$$

CALL `shop_vip_add_weapons`()$$

DROP PROCEDURE IF EXISTS `shop_vip_add_weapons`$$
DROP PROCEDURE IF EXISTS `shop_vip_add_set`$$

DELIMITER ;

SET SQL_SAFE_UPDATES = @VIP_SHOP_OLD_SQL_SAFE_UPDATES;

-- Expected: 2 groups, 621 armor products/entries, 45 weapon
-- products/entries and 1,149 product-item links (bundles included).
SELECT COUNT(*) AS `vip_shop_groups`
  FROM `battle_pay_group` WHERE `id` BETWEEN 20 AND 23;
SELECT COUNT(*) AS `vip_shop_armor_products`
  FROM `battle_pay_product`
 WHERE (`id` BETWEEN 910000 AND 910228)
    OR (`id` BETWEEN 920000 AND 920228)
    OR (`id` BETWEEN 930000 AND 930228);
SELECT COUNT(*) AS `vip_shop_weapon_products`
  FROM `battle_pay_product`
 WHERE (`id` BETWEEN 940000 AND 940014)
    OR (`id` BETWEEN 940100 AND 940114)
    OR (`id` BETWEEN 940200 AND 940214);
SELECT COUNT(*) AS `vip_shop_product_items`
  FROM `battle_pay_product_items`
 WHERE (`productId` BETWEEN 910000 AND 910228)
    OR (`productId` BETWEEN 920000 AND 920228)
    OR (`productId` BETWEEN 930000 AND 930228)
    OR (`productId` BETWEEN 940000 AND 940014)
    OR (`productId` BETWEEN 940100 AND 940114)
    OR (`productId` BETWEEN 940200 AND 940214);
