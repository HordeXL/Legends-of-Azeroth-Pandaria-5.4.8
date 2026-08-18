-- Complete the VIP3 class/spec PvE appearance blocks with non-set Siege of
-- Orgrimmar waist and wrist pieces, and label every armor piece by role.
--
-- Per ten-ID T16 block:
--   offsets 0-4 = genuine T16 set pieces
--   offset 5    = non-set SoO boots
--   offset 6    = non-set SoO waist
--   offset 7    = non-set SoO wrist
-- Waist, wrist and boots intentionally have itemset=0, preserving genuine T16
-- as a five-piece set.

SET @VIP3_SOO_EXTRA_OLD_SQL_SAFE_UPDATES := @@SQL_SAFE_UPDATES;
SET @VIP3_SOO_EXTRA_OLD_GROUP_CONCAT_MAX_LEN := @@GROUP_CONCAT_MAX_LEN;
SET SESSION GROUP_CONCAT_MAX_LEN = 1000000;
SET SQL_SAFE_UPDATES = 0;

DELIMITER $$

DROP PROCEDURE IF EXISTS `vip3_clone_soo_nonset_piece`$$
CREATE PROCEDURE `vip3_clone_soo_nonset_piece`(
    IN p_itemset INT UNSIGNED,
    IN p_offset INT UNSIGNED,
    IN p_source_entry INT UNSIGNED,
    IN p_inventory_type INT UNSIGNED,
    IN p_class_mask INT UNSIGNED,
    IN p_role VARCHAR(8)
)
BEGIN
    DECLARE v_new_entry INT UNSIGNED;
    DECLARE v_source_ok INT DEFAULT 0;
    DECLARE v_cols LONGTEXT;
    DECLARE v_select_cols LONGTEXT;
    DECLARE v_sql LONGTEXT;

    SET v_new_entry = 991000 + ((p_itemset - 1179) * 10) + p_offset;

    SELECT COUNT(*) INTO v_source_ok
      FROM `item_template`
     WHERE `entry` = p_source_entry
       AND `class` = 4
       AND `InventoryType` = p_inventory_type
       AND `RequiredLevel` = 90
       AND `ItemLevel` BETWEEN 553 AND 580;

    IF p_offset NOT IN (6,7) OR v_source_ok <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'VIP3 SoO waist/wrist source is missing or invalid';
    END IF;

    DELETE FROM `item_template` WHERE `entry` = v_new_entry;

    SELECT GROUP_CONCAT(CONCAT('`', `COLUMN_NAME`, '`')
                        ORDER BY `ORDINAL_POSITION` SEPARATOR ',')
      INTO v_cols
      FROM `information_schema`.`COLUMNS`
     WHERE `TABLE_SCHEMA` = DATABASE()
       AND `TABLE_NAME` = 'item_template';

    SELECT GROUP_CONCAT(
               CASE WHEN `COLUMN_NAME` = 'entry'
                    THEN v_new_entry
                    ELSE CONCAT('`', `COLUMN_NAME`, '`') END
               ORDER BY `ORDINAL_POSITION` SEPARATOR ',')
      INTO v_select_cols
      FROM `information_schema`.`COLUMNS`
     WHERE `TABLE_SCHEMA` = DATABASE()
       AND `TABLE_NAME` = 'item_template';

    SET v_sql = CONCAT(
        'INSERT INTO `item_template` (', v_cols, ') SELECT ',
        v_select_cols, ' FROM `item_template` WHERE `entry` = ',
        p_source_entry, ' LIMIT 1');
    SET @VIP3_SOO_EXTRA_SQL := v_sql;
    PREPARE vip3_soo_extra_stmt FROM @VIP3_SOO_EXTRA_SQL;
    EXECUTE vip3_soo_extra_stmt;
    DEALLOCATE PREPARE vip3_soo_extra_stmt;

    UPDATE `item_template`
       SET `name` = CONCAT('VIP3 PvE ', p_role, ' ', `name`),
           `description` = 'VIP3 solo PvE test armor. Genuine Siege of Orgrimmar appearance; does not alter the genuine T16 5-piece set bonus.',
           `Quality` = 5,
           `AllowableClass` = p_class_mask,
           `AllowableRace` = -1,
           `ItemLevel` = 700,
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
           `itemset` = 0,
           `stat_type1` = 7,  `stat_value1` = 6000,
           `stat_type2` = 4,  `stat_value2` = 3000,
           `stat_type3` = 3,  `stat_value3` = 3000,
           `stat_type4` = 5,  `stat_value4` = 3000,
           `stat_type5` = 6,  `stat_value5` = 2100,
           `stat_type6` = 13, `stat_value6` = 1650,
           `stat_type7` = 14, `stat_value7` = 1650,
           `stat_type8` = 32, `stat_value8` = 3000,
           `stat_type9` = 36, `stat_value9` = 3000,
           `stat_type10` = 49, `stat_value10` = 3000
     WHERE `entry` = v_new_entry;
END$$

DROP PROCEDURE IF EXISTS `vip3_set_block_role_name`$$
CREATE PROCEDURE `vip3_set_block_role_name`(
    IN p_itemset INT UNSIGNED,
    IN p_role VARCHAR(8)
)
BEGIN
    DECLARE v_first INT UNSIGNED;
    SET v_first = 991000 + ((p_itemset - 1179) * 10);

    UPDATE `item_template`
       SET `name` = CONCAT(
           'VIP3 PvE ', p_role, ' ',
           CASE
             WHEN `name` LIKE 'VIP3 PvE Tank %' THEN SUBSTRING(`name`, 15)
             WHEN `name` LIKE 'VIP3 PvE Heal %' THEN SUBSTRING(`name`, 15)
             WHEN `name` LIKE 'VIP3 PvE DPS %'  THEN SUBSTRING(`name`, 14)
             WHEN `name` LIKE 'VIP3 PvE %'      THEN SUBSTRING(`name`, 10)
             ELSE `name`
           END)
     WHERE `entry` BETWEEN v_first AND v_first + 7;
END$$

DROP PROCEDURE IF EXISTS `vip3_vendor_link_soo_extra`$$
CREATE PROCEDURE `vip3_vendor_link_soo_extra`(IN p_item INT UNSIGNED)
BEGIN
    DECLARE v_slot INT DEFAULT 0;
    SELECT COALESCE(MAX(`slot`), -1) + 1 INTO v_slot
      FROM `npc_vendor` WHERE `entry` = 990902;
    INSERT INTO `npc_vendor`
        (`entry`,`slot`,`item`,`maxcount`,`incrtime`,`ExtendedCost`,`type`)
    VALUES
        (990902,v_slot,p_item,0,0,0,1);
END$$

-- Warrior: protection, arms/fury.
CALL `vip3_clone_soo_nonset_piece`(1179,6,104537,6,1,'Tank')$$
CALL `vip3_clone_soo_nonset_piece`(1179,7,104475,9,1,'Tank')$$
CALL `vip3_clone_soo_nonset_piece`(1180,6,104513,6,1,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1180,7,104568,9,1,'DPS')$$
-- Warlock.
CALL `vip3_clone_soo_nonset_piece`(1181,6,104573,6,256,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1181,7,104446,9,256,'DPS')$$
-- Shaman: elemental, enhancement, restoration.
CALL `vip3_clone_soo_nonset_piece`(1182,6,104490,6,64,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1182,7,104491,9,64,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1183,6,104588,6,64,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1183,7,104566,9,64,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1184,6,104547,6,64,'Heal')$$
CALL `vip3_clone_soo_nonset_piece`(1184,7,104602,9,64,'Heal')$$
-- Rogue.
CALL `vip3_clone_soo_nonset_piece`(1185,6,104532,6,8,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1185,7,104509,9,8,'DPS')$$
-- Priest: shadow, discipline/holy.
CALL `vip3_clone_soo_nonset_piece`(1186,6,104519,6,16,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1186,7,104465,9,16,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1187,6,104467,6,16,'Heal')$$
CALL `vip3_clone_soo_nonset_piece`(1187,7,104498,9,16,'Heal')$$
-- Paladin: protection, holy, retribution.
CALL `vip3_clone_soo_nonset_piece`(1188,6,104537,6,2,'Tank')$$
CALL `vip3_clone_soo_nonset_piece`(1188,7,104475,9,2,'Tank')$$
CALL `vip3_clone_soo_nonset_piece`(1189,6,104603,6,2,'Heal')$$
CALL `vip3_clone_soo_nonset_piece`(1189,7,104415,9,2,'Heal')$$
CALL `vip3_clone_soo_nonset_piece`(1190,6,104591,6,2,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1190,7,104568,9,2,'DPS')$$
-- Monk: windwalker, mistweaver, brewmaster.
CALL `vip3_clone_soo_nonset_piece`(1191,6,104532,6,512,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1191,7,104509,9,512,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1192,6,104504,6,512,'Heal')$$
CALL `vip3_clone_soo_nonset_piece`(1192,7,104429,9,512,'Heal')$$
CALL `vip3_clone_soo_nonset_piece`(1193,6,104655,6,512,'Tank')$$
CALL `vip3_clone_soo_nonset_piece`(1193,7,104581,9,512,'Tank')$$
-- Mage and hunter.
CALL `vip3_clone_soo_nonset_piece`(1194,6,104573,6,128,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1194,7,104446,9,128,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1195,6,104588,6,4,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1195,7,104566,9,4,'DPS')$$
-- Druid: feral, balance, restoration, guardian.
CALL `vip3_clone_soo_nonset_piece`(1196,6,104532,6,1024,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1196,7,104509,9,1024,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1197,6,104639,6,1024,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1197,7,104620,9,1024,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1198,6,104504,6,1024,'Heal')$$
CALL `vip3_clone_soo_nonset_piece`(1198,7,104429,9,1024,'Heal')$$
CALL `vip3_clone_soo_nonset_piece`(1199,6,104655,6,1024,'Tank')$$
CALL `vip3_clone_soo_nonset_piece`(1199,7,104581,9,1024,'Tank')$$
-- Death knight: frost/unholy, blood.
CALL `vip3_clone_soo_nonset_piece`(1200,6,104591,6,32,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1200,7,104568,9,32,'DPS')$$
CALL `vip3_clone_soo_nonset_piece`(1201,6,104537,6,32,'Tank')$$
CALL `vip3_clone_soo_nonset_piece`(1201,7,104475,9,32,'Tank')$$

-- Label every item in each class/spec appearance block, including its T16
-- five-piece armor, boots, waist and wrist.
CALL `vip3_set_block_role_name`(1179,'Tank')$$
CALL `vip3_set_block_role_name`(1180,'DPS')$$
CALL `vip3_set_block_role_name`(1181,'DPS')$$
CALL `vip3_set_block_role_name`(1182,'DPS')$$
CALL `vip3_set_block_role_name`(1183,'DPS')$$
CALL `vip3_set_block_role_name`(1184,'Heal')$$
CALL `vip3_set_block_role_name`(1185,'DPS')$$
CALL `vip3_set_block_role_name`(1186,'DPS')$$
CALL `vip3_set_block_role_name`(1187,'Heal')$$
CALL `vip3_set_block_role_name`(1188,'Tank')$$
CALL `vip3_set_block_role_name`(1189,'Heal')$$
CALL `vip3_set_block_role_name`(1190,'DPS')$$
CALL `vip3_set_block_role_name`(1191,'DPS')$$
CALL `vip3_set_block_role_name`(1192,'Heal')$$
CALL `vip3_set_block_role_name`(1193,'Tank')$$
CALL `vip3_set_block_role_name`(1194,'DPS')$$
CALL `vip3_set_block_role_name`(1195,'DPS')$$
CALL `vip3_set_block_role_name`(1196,'DPS')$$
CALL `vip3_set_block_role_name`(1197,'DPS')$$
CALL `vip3_set_block_role_name`(1198,'Heal')$$
CALL `vip3_set_block_role_name`(1199,'Tank')$$
CALL `vip3_set_block_role_name`(1200,'DPS')$$
CALL `vip3_set_block_role_name`(1201,'Tank')$$

-- Idempotently rebuild only this update's waist/wrist vendor offers.
DELETE FROM `npc_vendor`
 WHERE `entry` = 990902
   AND `item` BETWEEN 991006 AND 991227
   AND MOD(`item` - 991000, 10) IN (6,7)$$

DROP PROCEDURE IF EXISTS `vip3_link_all_soo_extras`$$
CREATE PROCEDURE `vip3_link_all_soo_extras`()
BEGIN
    DECLARE v_set INT DEFAULT 1179;
    DECLARE v_first INT UNSIGNED;
    WHILE v_set <= 1201 DO
        SET v_first = 991000 + ((v_set - 1179) * 10);
        CALL `vip3_vendor_link_soo_extra`(v_first + 6);
        CALL `vip3_vendor_link_soo_extra`(v_first + 7);
        SET v_set = v_set + 1;
    END WHILE;
END$$
CALL `vip3_link_all_soo_extras`()$$

DROP PROCEDURE IF EXISTS `vip3_link_all_soo_extras`$$
DROP PROCEDURE IF EXISTS `vip3_vendor_link_soo_extra`$$
DROP PROCEDURE IF EXISTS `vip3_set_block_role_name`$$
DROP PROCEDURE IF EXISTS `vip3_clone_soo_nonset_piece`$$

DELIMITER ;

SET SESSION GROUP_CONCAT_MAX_LEN = @VIP3_SOO_EXTRA_OLD_GROUP_CONCAT_MAX_LEN;
SET SQL_SAFE_UPDATES = @VIP3_SOO_EXTRA_OLD_SQL_SAFE_UPDATES;

-- Expected: 46 new non-set pieces, role labels on all 184 block items and
-- 207 distinct VIP3 vendor offers.
SELECT COUNT(*) AS `vip3_soo_waist_wrist`
  FROM `item_template`
 WHERE `entry` BETWEEN 991006 AND 991227
   AND MOD(`entry` - 991000, 10) IN (6,7)
   AND `InventoryType` IN (6,9)
   AND `itemset` = 0;
SELECT COUNT(*) AS `vip3_role_labeled_block_items`
  FROM `item_template`
 WHERE `entry` BETWEEN 991000 AND 991227
   AND MOD(`entry` - 991000, 10) BETWEEN 0 AND 7
   AND (`name` LIKE 'VIP3 PvE Tank %'
        OR `name` LIKE 'VIP3 PvE Heal %'
        OR `name` LIKE 'VIP3 PvE DPS %');
SELECT COUNT(*) AS `vip3_vendor_items`
  FROM `npc_vendor`
 WHERE `entry` = 990902;
