-- VIP3 solo PvE test armor for MoP 5.4.8.
--
-- The old 990200-990231 items are intentionally preserved because characters
-- may already own them.  Only the VIP3 vendor offer is changed: the old
-- universal/PvP armor is replaced by class-appropriate Siege of Orgrimmar
-- T16 appearances with the genuine PvE ItemSet.dbc IDs.  Five armor pieces
-- therefore produce a real 5/5 PvE set instead of counting every armor slot
-- toward the old PvP set.
--
-- Custom IDs are deterministic:
--   991000 + ((T16 itemset - 1179) * 10) + slot
--   slot 0=head, 1=shoulders, 2=chest, 3=legs, 4=hands
-- Existing accessories and weapons 990201/203/210-215/217-231 remain offered.

SET @VIP3_OLD_SQL_SAFE_UPDATES := @@SQL_SAFE_UPDATES;
SET @VIP3_OLD_GROUP_CONCAT_MAX_LEN := @@GROUP_CONCAT_MAX_LEN;
SET SESSION GROUP_CONCAT_MAX_LEN = 1000000;
SET SQL_SAFE_UPDATES = 0;

DELIMITER $$

DROP PROCEDURE IF EXISTS `vip3_clone_t16_piece`$$
CREATE PROCEDURE `vip3_clone_t16_piece`(
    IN p_new_entry INT UNSIGNED,
    IN p_base_entry INT UNSIGNED,
    IN p_itemset INT UNSIGNED,
    IN p_class_mask INT UNSIGNED
)
BEGIN
    DECLARE v_cols LONGTEXT;
    DECLARE v_select_cols LONGTEXT;
    DECLARE v_sql LONGTEXT;
    DECLARE v_base_set INT DEFAULT 0;

    SELECT `itemset` INTO v_base_set
      FROM `item_template`
     WHERE `entry` = p_base_entry
     LIMIT 1;

    IF v_base_set <> p_itemset THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'VIP3 T16 source item or ItemSet is missing';
    END IF;

    -- Idempotent replacement is limited strictly to this update's custom IDs.
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
    SET @VIP3_T16_SQL := v_sql;
    PREPARE vip3_stmt FROM @VIP3_T16_SQL;
    EXECUTE vip3_stmt;
    DEALLOCATE PREPARE vip3_stmt;

    UPDATE `item_template`
       SET `name` = CONCAT('VIP3 PvE ', `name`),
           `description` = 'VIP3 solo PvE test armor. Siege of Orgrimmar T16 appearance and genuine 5-piece PvE set bonus.',
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
     WHERE `entry` = p_new_entry;
END$$

DROP PROCEDURE IF EXISTS `vip3_clone_t16_set`$$
CREATE PROCEDURE `vip3_clone_t16_set`(
    IN p_itemset INT UNSIGNED,
    IN p_class_mask INT UNSIGNED,
    IN p_head INT UNSIGNED,
    IN p_shoulders INT UNSIGNED,
    IN p_chest INT UNSIGNED,
    IN p_legs INT UNSIGNED,
    IN p_hands INT UNSIGNED
)
BEGIN
    DECLARE v_first INT UNSIGNED;
    SET v_first = 991000 + ((p_itemset - 1179) * 10);
    CALL `vip3_clone_t16_piece`(v_first + 0, p_head,      p_itemset, p_class_mask);
    CALL `vip3_clone_t16_piece`(v_first + 1, p_shoulders, p_itemset, p_class_mask);
    CALL `vip3_clone_t16_piece`(v_first + 2, p_chest,     p_itemset, p_class_mask);
    CALL `vip3_clone_t16_piece`(v_first + 3, p_legs,      p_itemset, p_class_mask);
    CALL `vip3_clone_t16_piece`(v_first + 4, p_hands,     p_itemset, p_class_mask);
END$$

-- Warrior: protection, then arms/fury.
CALL `vip3_clone_t16_set`(1179, 1, 99409,99407,99415,99410,99408)$$
CALL `vip3_clone_t16_set`(1180, 1, 99418,99414,99411,99413,99412)$$
-- Warlock.
CALL `vip3_clone_t16_set`(1181, 256, 99425,99417,99416,99426,99424)$$
-- Shaman: elemental, enhancement, restoration.
CALL `vip3_clone_t16_set`(1182, 64, 99332,99334,99344,99333,99345)$$
CALL `vip3_clone_t16_set`(1183, 64, 99341,99343,99347,99342,99340)$$
CALL `vip3_clone_t16_set`(1184, 64, 99353,99346,99351,99354,99352)$$
-- Rogue.
CALL `vip3_clone_t16_set`(1185, 8, 99348,99350,99356,99349,99355)$$
-- Priest: shadow, then discipline/holy.
CALL `vip3_clone_t16_set`(1186, 16, 99360,99363,99362,99361,99359)$$
CALL `vip3_clone_t16_set`(1187, 16, 99366,99358,99357,99367,99365)$$
-- Paladin: protection, holy, retribution.
CALL `vip3_clone_t16_set`(1188, 2, 99370,99364,99368,99371,99369)$$
CALL `vip3_clone_t16_set`(1189, 2, 99376,99378,99374,99377,99375)$$
CALL `vip3_clone_t16_set`(1190, 2, 99379,99373,99387,99372,99380)$$
-- Monk: windwalker, mistweaver, brewmaster.
CALL `vip3_clone_t16_set`(1191, 512, 99384,99386,99382,99385,99383)$$
CALL `vip3_clone_t16_set`(1192, 512, 99389,99381,99391,99390,99388)$$
CALL `vip3_clone_t16_set`(1193, 512, 99393,99395,99396,99394,99392)$$
-- Mage and hunter.
CALL `vip3_clone_t16_set`(1194, 128, 99398,99401,99400,99399,99397)$$
CALL `vip3_clone_t16_set`(1195, 4, 99402,99404,99405,99403,99406)$$
-- Druid: feral, balance, restoration, guardian.
CALL `vip3_clone_t16_set`(1196, 1024, 99421,99423,99419,99422,99420)$$
CALL `vip3_clone_t16_set`(1197, 1024, 99433,99428,99427,99434,99432)$$
CALL `vip3_clone_t16_set`(1198, 1024, 99436,99431,99430,99429,99435)$$
CALL `vip3_clone_t16_set`(1199, 1024, 99328,99322,99326,99329,99327)$$
-- Death knight: frost/unholy, then blood.
CALL `vip3_clone_t16_set`(1200, 32, 99337,99339,99335,99338,99336)$$
CALL `vip3_clone_t16_set`(1201, 32, 99323,99325,99330,99324,99331)$$

DROP PROCEDURE IF EXISTS `vip3_vendor_link`$$
CREATE PROCEDURE `vip3_vendor_link`(IN p_item INT UNSIGNED)
BEGIN
    DECLARE v_slot INT DEFAULT 0;
    SELECT COALESCE(MAX(`slot`), -1) + 1 INTO v_slot
      FROM `npc_vendor` WHERE `entry` = 990902;
    INSERT INTO `npc_vendor`
        (`entry`,`slot`,`item`,`maxcount`,`incrtime`,`ExtendedCost`,`type`)
    VALUES
        (990902,v_slot,p_item,0,0,0,1);
END$$

-- Remove only the obsolete vendor links, never the old owned item templates.
DELETE FROM `npc_vendor`
 WHERE `entry` = 990902
   AND (`item` IN (990200,990202,990204,990205,990206,990207,990208,990209,990216)
        OR `item` BETWEEN 991000 AND 991224)$$

-- Add every deterministic T16 custom entry (five entries per ten-ID block).
DROP PROCEDURE IF EXISTS `vip3_link_all_t16`$$
CREATE PROCEDURE `vip3_link_all_t16`()
BEGIN
    DECLARE v_set INT DEFAULT 1179;
    DECLARE v_slot_offset INT;
    WHILE v_set <= 1201 DO
        SET v_slot_offset = 0;
        WHILE v_slot_offset < 5 DO
            CALL `vip3_vendor_link`(
                991000 + ((v_set - 1179) * 10) + v_slot_offset);
            SET v_slot_offset = v_slot_offset + 1;
        END WHILE;
        SET v_set = v_set + 1;
    END WHILE;
END$$
CALL `vip3_link_all_t16`()$$

DROP PROCEDURE IF EXISTS `vip3_link_all_t16`$$
DROP PROCEDURE IF EXISTS `vip3_vendor_link`$$
DROP PROCEDURE IF EXISTS `vip3_clone_t16_set`$$
DROP PROCEDURE IF EXISTS `vip3_clone_t16_piece`$$

DELIMITER ;

SET SESSION GROUP_CONCAT_MAX_LEN = @VIP3_OLD_GROUP_CONCAT_MAX_LEN;
SET SQL_SAFE_UPDATES = @VIP3_OLD_SQL_SAFE_UPDATES;

-- Expected: 115 custom T16 pieces, 138 total VIP3 vendor offers.
SELECT COUNT(*) AS `vip3_t16_items`
  FROM `item_template`
 WHERE (CAST(`entry` AS SIGNED) - 991000) DIV 10 BETWEEN 0 AND 22
   AND (CAST(`entry` AS SIGNED) - 991000) MOD 10 BETWEEN 0 AND 4;
SELECT COUNT(*) AS `vip3_vendor_items`
  FROM `npc_vendor`
 WHERE `entry` = 990902;
