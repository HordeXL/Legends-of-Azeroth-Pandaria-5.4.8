-- Replace the universal VIP1/VIP2 armor vendor offers with genuine class PvE
-- tier appearances and set bonuses while preserving the historical owned item
-- templates. VIP1 uses T14 and VIP2 uses T15; VIP3 already uses T16.
--
-- Deterministic custom IDs:
--   VIP1: 992000 + ((T14 itemset - 1123) * 10) + slot
--   VIP2: 993000 + ((T15 itemset - 1151) * 10) + slot
--   slot 0=head, 1=shoulders, 2=chest, 3=legs, 4=hands,
--        5=boots, 6=waist, 7=wrists
-- Only slots 0-4 retain the genuine ItemSet ID. Slots 5-7 use matching
-- same-tier raid appearances but itemset=0, so they cannot inflate 5/5.

SET @VIP12_OLD_SQL_SAFE_UPDATES := @@SQL_SAFE_UPDATES;
SET @VIP12_OLD_GROUP_CONCAT_MAX_LEN := @@GROUP_CONCAT_MAX_LEN;
SET SESSION GROUP_CONCAT_MAX_LEN = 1000000;
SET SQL_SAFE_UPDATES = 0;

DELIMITER $$

DROP PROCEDURE IF EXISTS `vip12_clone_item`$$
CREATE PROCEDURE `vip12_clone_item`(
    IN p_new_entry INT UNSIGNED,
    IN p_base_entry INT UNSIGNED,
    IN p_itemset INT UNSIGNED,
    IN p_class_mask INT UNSIGNED,
    IN p_vip_rank TINYINT UNSIGNED,
    IN p_tier_name VARCHAR(16),
    IN p_role VARCHAR(8),
    IN p_is_set TINYINT UNSIGNED
)
BEGIN
    DECLARE v_cols LONGTEXT;
    DECLARE v_select_cols LONGTEXT;
    DECLARE v_sql LONGTEXT;

    IF p_base_entry IS NULL OR p_base_entry = p_new_entry OR
       NOT EXISTS (SELECT 1 FROM `item_template` WHERE `entry` = p_base_entry) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'VIP1/VIP2 tier source item is missing';
    END IF;

    DELETE FROM `item_template` WHERE `entry` = p_new_entry;

    SELECT GROUP_CONCAT(CONCAT('`', `COLUMN_NAME`, '`')
                        ORDER BY `ORDINAL_POSITION` SEPARATOR ',')
      INTO v_cols
      FROM `information_schema`.`COLUMNS`
     WHERE `TABLE_SCHEMA` = DATABASE()
       AND `TABLE_NAME` = 'item_template';

    SELECT GROUP_CONCAT(
               CASE WHEN `COLUMN_NAME` = 'entry'
                    THEN p_new_entry
                    ELSE CONCAT('`', `COLUMN_NAME`, '`') END
               ORDER BY `ORDINAL_POSITION` SEPARATOR ',')
      INTO v_select_cols
      FROM `information_schema`.`COLUMNS`
     WHERE `TABLE_SCHEMA` = DATABASE()
       AND `TABLE_NAME` = 'item_template';

    SET v_sql = CONCAT(
        'INSERT INTO `item_template` (', v_cols, ') SELECT ',
        v_select_cols, ' FROM `item_template` WHERE `entry` = ',
        p_base_entry, ' LIMIT 1');
    SET @VIP12_CLONE_SQL := v_sql;
    PREPARE vip12_clone_stmt FROM @VIP12_CLONE_SQL;
    EXECUTE vip12_clone_stmt;
    DEALLOCATE PREPARE vip12_clone_stmt;

    UPDATE `item_template`
       SET `name` = CONCAT('VIP', p_vip_rank, ' PvE ', p_role, ' ', `name`),
           `description` = IF(p_is_set = 1,
               CONCAT('VIP', p_vip_rank, ' solo PvE test armor. Genuine ',
                      p_tier_name, ' class appearance and genuine 2/4-piece PvE set bonuses.'),
               CONCAT('VIP', p_vip_rank, ' solo PvE test armor. Matching ',
                      p_tier_name, ' raid appearance; does not count toward the five-piece tier set.')),
           `Quality` = 5,
           `AllowableClass` = p_class_mask,
           `AllowableRace` = -1,
           `ItemLevel` = IF(p_vip_rank = 1, 600, 650),
           `RequiredLevel` = 90,
           `BuyPrice` = 0,
           `SellPrice` = 0,
           `BuyCount` = 1,
           `bonding` = 1,
           `maxcount` = 0,
           `stackable` = 1,
           `RequiredSkill` = 0,
           `RequiredSkillRank` = 0,
           `RequiredReputationFaction` = 0,
           `RequiredReputationRank` = 0,
           `RandomProperty` = 0,
           `RandomSuffix` = 0,
           `itemset` = IF(p_is_set = 1, p_itemset, 0),
           `stat_type1` = 7,  `stat_value1` = IF(p_vip_rank = 1, 1800, 3200),
           `stat_type2` = 4,  `stat_value2` = IF(p_vip_rank = 1,  900, 1600),
           `stat_type3` = 3,  `stat_value3` = IF(p_vip_rank = 1,  900, 1600),
           `stat_type4` = 5,  `stat_value4` = IF(p_vip_rank = 1,  900, 1600),
           `stat_type5` = 6,  `stat_value5` = IF(p_vip_rank = 1,  630, 1120),
           `stat_type6` = 13, `stat_value6` = IF(p_vip_rank = 1,  495,  880),
           `stat_type7` = 14, `stat_value7` = IF(p_vip_rank = 1,  495,  880),
           `stat_type8` = 32, `stat_value8` = IF(p_vip_rank = 1,  900, 1600),
           `stat_type9` = 36, `stat_value9` = IF(p_vip_rank = 1,  900, 1600),
           `stat_type10` = 49,`stat_value10`= IF(p_vip_rank = 1,  900, 1600)
     WHERE `entry` = p_new_entry;
END$$

DROP PROCEDURE IF EXISTS `vip12_clone_tier_piece`$$
CREATE PROCEDURE `vip12_clone_tier_piece`(
    IN p_vip_rank TINYINT UNSIGNED,
    IN p_set_base INT UNSIGNED,
    IN p_itemset INT UNSIGNED,
    IN p_class_mask INT UNSIGNED,
    IN p_role VARCHAR(8),
    IN p_slot TINYINT UNSIGNED,
    IN p_inventory_a TINYINT UNSIGNED,
    IN p_inventory_b TINYINT UNSIGNED
)
BEGIN
    DECLARE v_base_entry INT UNSIGNED DEFAULT NULL;
    DECLARE v_new_entry INT UNSIGNED;
    DECLARE v_tier_name VARCHAR(16);

    SELECT `entry` INTO v_base_entry
     FROM `item_template`
     WHERE `itemset` = p_itemset
       AND `entry` < 990000
       AND (`InventoryType` = p_inventory_a OR
            (p_inventory_b <> 0 AND `InventoryType` = p_inventory_b))
     ORDER BY `ItemLevel` DESC, `entry` DESC
     LIMIT 1;

    SET v_new_entry = IF(p_vip_rank = 1, 992000, 993000) +
        ((p_itemset - p_set_base) * 10) + p_slot;
    SET v_tier_name = IF(p_vip_rank = 1, 'T14', 'T15');
    CALL `vip12_clone_item`(v_new_entry, v_base_entry, p_itemset,
        p_class_mask, p_vip_rank, v_tier_name, p_role, 1);
END$$

DROP PROCEDURE IF EXISTS `vip12_clone_extra_piece`$$
CREATE PROCEDURE `vip12_clone_extra_piece`(
    IN p_vip_rank TINYINT UNSIGNED,
    IN p_set_base INT UNSIGNED,
    IN p_itemset INT UNSIGNED,
    IN p_class_mask INT UNSIGNED,
    IN p_role VARCHAR(8),
    IN p_slot TINYINT UNSIGNED,
    IN p_inventory TINYINT UNSIGNED
)
BEGIN
    DECLARE v_armor_subclass TINYINT UNSIGNED DEFAULT NULL;
    DECLARE v_source_level INT UNSIGNED;
    DECLARE v_candidate_count INT UNSIGNED DEFAULT 0;
    DECLARE v_pick INT UNSIGNED DEFAULT 0;
    DECLARE v_base_entry INT UNSIGNED DEFAULT NULL;
    DECLARE v_new_entry INT UNSIGNED;
    DECLARE v_tier_name VARCHAR(16);

    SELECT `subclass` INTO v_armor_subclass
      FROM `item_template`
     WHERE `itemset` = p_itemset
       AND `class` = 4
     ORDER BY `ItemLevel` DESC, `entry` DESC
     LIMIT 1;

    SET v_source_level = IF(p_vip_rank = 1, 509, 535);
    SELECT COUNT(*) INTO v_candidate_count
      FROM `item_template`
     WHERE `entry` < 990000
       AND `class` = 4
       AND `subclass` = v_armor_subclass
       AND `InventoryType` = p_inventory
       AND `ItemLevel` = v_source_level
       AND `Quality` >= 4
       AND `itemset` = 0;

    IF v_candidate_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'VIP1/VIP2 matching raid appearance is missing';
    END IF;

    SET v_pick = (p_itemset - p_set_base) MOD v_candidate_count;
    SELECT `entry` INTO v_base_entry
      FROM `item_template`
     WHERE `entry` < 990000
       AND `class` = 4
       AND `subclass` = v_armor_subclass
       AND `InventoryType` = p_inventory
       AND `ItemLevel` = v_source_level
       AND `Quality` >= 4
       AND `itemset` = 0
     ORDER BY `entry`
     LIMIT v_pick, 1;

    SET v_new_entry = IF(p_vip_rank = 1, 992000, 993000) +
        ((p_itemset - p_set_base) * 10) + p_slot;
    SET v_tier_name = IF(p_vip_rank = 1, 'T14', 'T15');
    CALL `vip12_clone_item`(v_new_entry, v_base_entry, 0,
        p_class_mask, p_vip_rank, v_tier_name, p_role, 0);
END$$

DROP PROCEDURE IF EXISTS `vip12_clone_set`$$
CREATE PROCEDURE `vip12_clone_set`(
    IN p_vip_rank TINYINT UNSIGNED,
    IN p_set_base INT UNSIGNED,
    IN p_itemset INT UNSIGNED,
    IN p_class_mask INT UNSIGNED,
    IN p_role VARCHAR(8)
)
BEGIN
    CALL `vip12_clone_tier_piece`(p_vip_rank,p_set_base,p_itemset,p_class_mask,p_role,0,1,0);
    CALL `vip12_clone_tier_piece`(p_vip_rank,p_set_base,p_itemset,p_class_mask,p_role,1,3,0);
    CALL `vip12_clone_tier_piece`(p_vip_rank,p_set_base,p_itemset,p_class_mask,p_role,2,5,20);
    CALL `vip12_clone_tier_piece`(p_vip_rank,p_set_base,p_itemset,p_class_mask,p_role,3,7,0);
    CALL `vip12_clone_tier_piece`(p_vip_rank,p_set_base,p_itemset,p_class_mask,p_role,4,10,0);
    CALL `vip12_clone_extra_piece`(p_vip_rank,p_set_base,p_itemset,p_class_mask,p_role,5,8);
    CALL `vip12_clone_extra_piece`(p_vip_rank,p_set_base,p_itemset,p_class_mask,p_role,6,6);
    CALL `vip12_clone_extra_piece`(p_vip_rank,p_set_base,p_itemset,p_class_mask,p_role,7,9);
END$$

-- VIP1 / T14.
CALL `vip12_clone_set`(1,1123,1123,32,'DPS')$$
CALL `vip12_clone_set`(1,1123,1124,32,'Tank')$$
CALL `vip12_clone_set`(1,1123,1125,1024,'Heal')$$
CALL `vip12_clone_set`(1,1123,1126,1024,'DPS')$$
CALL `vip12_clone_set`(1,1123,1127,1024,'DPS')$$
CALL `vip12_clone_set`(1,1123,1128,1024,'Tank')$$
CALL `vip12_clone_set`(1,1123,1129,4,'DPS')$$
CALL `vip12_clone_set`(1,1123,1130,128,'DPS')$$
CALL `vip12_clone_set`(1,1123,1131,512,'Heal')$$
CALL `vip12_clone_set`(1,1123,1132,512,'DPS')$$
CALL `vip12_clone_set`(1,1123,1133,512,'Tank')$$
CALL `vip12_clone_set`(1,1123,1134,2,'Heal')$$
CALL `vip12_clone_set`(1,1123,1135,2,'DPS')$$
CALL `vip12_clone_set`(1,1123,1136,2,'Tank')$$
CALL `vip12_clone_set`(1,1123,1137,16,'Heal')$$
CALL `vip12_clone_set`(1,1123,1138,16,'DPS')$$
CALL `vip12_clone_set`(1,1123,1139,8,'DPS')$$
CALL `vip12_clone_set`(1,1123,1140,64,'Heal')$$
CALL `vip12_clone_set`(1,1123,1141,64,'DPS')$$
CALL `vip12_clone_set`(1,1123,1142,64,'DPS')$$
CALL `vip12_clone_set`(1,1123,1143,256,'DPS')$$
CALL `vip12_clone_set`(1,1123,1144,1,'DPS')$$
CALL `vip12_clone_set`(1,1123,1145,1,'Tank')$$

-- VIP2 / T15.
CALL `vip12_clone_set`(2,1151,1151,32,'Tank')$$
CALL `vip12_clone_set`(2,1151,1152,32,'DPS')$$
CALL `vip12_clone_set`(2,1151,1153,1024,'DPS')$$
CALL `vip12_clone_set`(2,1151,1154,1024,'Heal')$$
CALL `vip12_clone_set`(2,1151,1155,1024,'DPS')$$
CALL `vip12_clone_set`(2,1151,1156,1024,'Tank')$$
CALL `vip12_clone_set`(2,1151,1157,4,'DPS')$$
CALL `vip12_clone_set`(2,1151,1158,128,'DPS')$$
CALL `vip12_clone_set`(2,1151,1159,512,'DPS')$$
CALL `vip12_clone_set`(2,1151,1160,512,'Heal')$$
CALL `vip12_clone_set`(2,1151,1161,512,'Tank')$$
CALL `vip12_clone_set`(2,1151,1162,2,'DPS')$$
CALL `vip12_clone_set`(2,1151,1163,2,'Heal')$$
CALL `vip12_clone_set`(2,1151,1164,2,'Tank')$$
CALL `vip12_clone_set`(2,1151,1165,16,'Heal')$$
CALL `vip12_clone_set`(2,1151,1166,16,'DPS')$$
CALL `vip12_clone_set`(2,1151,1167,8,'DPS')$$
CALL `vip12_clone_set`(2,1151,1168,64,'Heal')$$
CALL `vip12_clone_set`(2,1151,1169,64,'DPS')$$
CALL `vip12_clone_set`(2,1151,1170,64,'DPS')$$
CALL `vip12_clone_set`(2,1151,1171,256,'DPS')$$
CALL `vip12_clone_set`(2,1151,1172,1,'DPS')$$
CALL `vip12_clone_set`(2,1151,1173,1,'Tank')$$

DROP PROCEDURE IF EXISTS `vip12_vendor_link`$$
CREATE PROCEDURE `vip12_vendor_link`(
    IN p_vendor INT UNSIGNED,
    IN p_item INT UNSIGNED
)
BEGIN
    DECLARE v_slot INT DEFAULT 0;
    SELECT COALESCE(MAX(`slot`), -1) + 1 INTO v_slot
      FROM `npc_vendor` WHERE `entry` = p_vendor;
    INSERT INTO `npc_vendor`
        (`entry`,`slot`,`item`,`maxcount`,`incrtime`,`ExtendedCost`,`type`)
    VALUES
        (p_vendor,v_slot,p_item,0,0,0,1);
END$$

-- Keep old owned templates valid, but remove their universal armor offers.
DELETE FROM `npc_vendor`
 WHERE (`entry` = 990900 AND
        (`item` IN (990000,990002,990004,990005,990006,990007,990008,990009,990016)
         OR `item` BETWEEN 992000 AND 992227))
    OR (`entry` = 990901 AND
        (`item` IN (990100,990102,990104,990105,990106,990107,990108,990109,990116)
         OR `item` BETWEEN 993000 AND 993227))$$

DROP PROCEDURE IF EXISTS `vip12_link_all_sets`$$
CREATE PROCEDURE `vip12_link_all_sets`(
    IN p_vendor INT UNSIGNED,
    IN p_first_entry INT UNSIGNED
)
BEGIN
    DECLARE v_block INT DEFAULT 0;
    DECLARE v_offset INT DEFAULT 0;
    WHILE v_block < 23 DO
        SET v_offset = 0;
        WHILE v_offset < 8 DO
            CALL `vip12_vendor_link`(p_vendor,
                p_first_entry + (v_block * 10) + v_offset);
            SET v_offset = v_offset + 1;
        END WHILE;
        SET v_block = v_block + 1;
    END WHILE;
END$$

CALL `vip12_link_all_sets`(990900,992000)$$
CALL `vip12_link_all_sets`(990901,993000)$$

DROP PROCEDURE IF EXISTS `vip12_link_all_sets`$$
DROP PROCEDURE IF EXISTS `vip12_vendor_link`$$
DROP PROCEDURE IF EXISTS `vip12_clone_set`$$
DROP PROCEDURE IF EXISTS `vip12_clone_extra_piece`$$
DROP PROCEDURE IF EXISTS `vip12_clone_tier_piece`$$
DROP PROCEDURE IF EXISTS `vip12_clone_item`$$

-- Clarify the already-installed VIP3 wording as well: MoP tier sets contain
-- five armor pieces, but their actual gameplay bonuses activate at 2/4 pieces.
UPDATE `item_template`
   SET `description` = 'VIP3 solo PvE test armor. Siege of Orgrimmar T16 appearance and genuine 2/4-piece PvE set bonuses.'
 WHERE `entry` BETWEEN 991000 AND 991227
   AND (`entry` - 991000) MOD 10 BETWEEN 0 AND 4$$

DELIMITER ;

SET SESSION GROUP_CONCAT_MAX_LEN = @VIP12_OLD_GROUP_CONCAT_MAX_LEN;
SET SQL_SAFE_UPDATES = @VIP12_OLD_SQL_SAFE_UPDATES;

-- Expected per rank: 184 custom armor items (115 genuine set pieces plus
-- 69 non-set boots/waists/wrists) and 207 total vendor offers.
SELECT COUNT(*) AS `vip1_t14_items`
  FROM `item_template`
 WHERE `entry` BETWEEN 992000 AND 992227
   AND (`entry` - 992000) MOD 10 BETWEEN 0 AND 7;
SELECT COUNT(*) AS `vip1_t14_set_pieces`
  FROM `item_template`
 WHERE `entry` BETWEEN 992000 AND 992227 AND `itemset` BETWEEN 1123 AND 1145;
SELECT COUNT(*) AS `vip1_vendor_items` FROM `npc_vendor` WHERE `entry` = 990900;
SELECT COUNT(*) AS `vip2_t15_items`
  FROM `item_template`
 WHERE `entry` BETWEEN 993000 AND 993227
   AND (`entry` - 993000) MOD 10 BETWEEN 0 AND 7;
SELECT COUNT(*) AS `vip2_t15_set_pieces`
  FROM `item_template`
 WHERE `entry` BETWEEN 993000 AND 993227 AND `itemset` BETWEEN 1151 AND 1173;
SELECT COUNT(*) AS `vip2_vendor_items` FROM `npc_vendor` WHERE `entry` = 990901;
