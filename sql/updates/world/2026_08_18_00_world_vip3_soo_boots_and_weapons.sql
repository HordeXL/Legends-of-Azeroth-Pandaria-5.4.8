-- Add class/spec-appropriate Siege of Orgrimmar boots to the VIP3 T16 PvE
-- overlay and explicitly pin every existing VIP3 weapon/off-hand appearance to
-- a genuine MoP 5.4.8 Siege of Orgrimmar source item.
--
-- The boots intentionally use itemset=0. Retail T16 contains only head,
-- shoulders, chest, legs and hands; making boots part of ItemSet 1179-1201
-- would incorrectly change the genuine 5/5 set relationship.
--
-- Deterministic boot ID:
--   991000 + ((T16 itemset - 1179) * 10) + 5
-- Existing VIP3 weapons/off-hands remain at 990217-990231. Their stats and
-- ownership are preserved; only displayid is sourced again from SoO items.

SET @VIP3_SOO_OLD_SQL_SAFE_UPDATES := @@SQL_SAFE_UPDATES;
SET @VIP3_SOO_OLD_GROUP_CONCAT_MAX_LEN := @@GROUP_CONCAT_MAX_LEN;
SET SESSION GROUP_CONCAT_MAX_LEN = 1000000;
SET SQL_SAFE_UPDATES = 0;

DELIMITER $$

DROP PROCEDURE IF EXISTS `vip3_clone_soo_boots`$$
CREATE PROCEDURE `vip3_clone_soo_boots`(
    IN p_itemset INT UNSIGNED,
    IN p_source_entry INT UNSIGNED,
    IN p_class_mask INT UNSIGNED
)
BEGIN
    DECLARE v_new_entry INT UNSIGNED;
    DECLARE v_source_ok INT DEFAULT 0;
    DECLARE v_cols LONGTEXT;
    DECLARE v_select_cols LONGTEXT;
    DECLARE v_sql LONGTEXT;

    SET v_new_entry = 991000 + ((p_itemset - 1179) * 10) + 5;

    SELECT COUNT(*) INTO v_source_ok
      FROM `item_template`
     WHERE `entry` = p_source_entry
       AND `class` = 4
       AND `InventoryType` = 8
       AND `RequiredLevel` = 90
       AND `ItemLevel` BETWEEN 553 AND 580;

    IF v_source_ok <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'VIP3 SoO boot source is missing or invalid';
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
    SET @VIP3_SOO_SQL := v_sql;
    PREPARE vip3_soo_stmt FROM @VIP3_SOO_SQL;
    EXECUTE vip3_soo_stmt;
    DEALLOCATE PREPARE vip3_soo_stmt;

    UPDATE `item_template`
       SET `name` = CONCAT('VIP3 PvE ', `name`),
           `description` = 'VIP3 solo PvE test boots. Genuine Siege of Orgrimmar appearance; does not alter the genuine T16 5-piece set bonus.',
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

DROP PROCEDURE IF EXISTS `vip3_pin_soo_display`$$
CREATE PROCEDURE `vip3_pin_soo_display`(
    IN p_target_entry INT UNSIGNED,
    IN p_source_entry INT UNSIGNED,
    IN p_source_class INT UNSIGNED,
    IN p_source_subclass INT UNSIGNED
)
BEGIN
    DECLARE v_source_display INT UNSIGNED DEFAULT 0;
    DECLARE v_target_ok INT DEFAULT 0;

    SELECT `displayid` INTO v_source_display
      FROM `item_template`
     WHERE `entry` = p_source_entry
       AND `class` = p_source_class
       AND `subclass` = p_source_subclass
       AND `RequiredLevel` = 90
       AND `ItemLevel` BETWEEN 553 AND 580
     LIMIT 1;

    SELECT COUNT(*) INTO v_target_ok
      FROM `item_template`
     WHERE `entry` = p_target_entry;

    IF v_source_display = 0 OR v_target_ok <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'VIP3 SoO weapon target or source is missing';
    END IF;

    UPDATE `item_template`
       SET `displayid` = v_source_display
     WHERE `entry` = p_target_entry;
END$$

DROP PROCEDURE IF EXISTS `vip3_vendor_link_soo`$$
CREATE PROCEDURE `vip3_vendor_link_soo`(IN p_item INT UNSIGNED)
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
CALL `vip3_clone_soo_boots`(1179,104432,1)$$
CALL `vip3_clone_soo_boots`(1180,104418,1)$$
-- Warlock.
CALL `vip3_clone_soo_boots`(1181,104541,256)$$
-- Shaman: elemental, enhancement, restoration.
CALL `vip3_clone_soo_boots`(1182,104414,64)$$
CALL `vip3_clone_soo_boots`(1183,104557,64)$$
CALL `vip3_clone_soo_boots`(1184,104622,64)$$
-- Rogue.
CALL `vip3_clone_soo_boots`(1185,104435,8)$$
-- Priest: shadow, discipline/holy.
CALL `vip3_clone_soo_boots`(1186,104443,16)$$
CALL `vip3_clone_soo_boots`(1187,104497,16)$$
-- Paladin: protection, holy, retribution.
CALL `vip3_clone_soo_boots`(1188,104482,2)$$
CALL `vip3_clone_soo_boots`(1189,104604,2)$$
CALL `vip3_clone_soo_boots`(1190,104529,2)$$
-- Monk: windwalker, mistweaver, brewmaster.
CALL `vip3_clone_soo_boots`(1191,104586,512)$$
CALL `vip3_clone_soo_boots`(1192,104580,512)$$
CALL `vip3_clone_soo_boots`(1193,104488,512)$$
-- Mage and hunter.
CALL `vip3_clone_soo_boots`(1194,104500,128)$$
CALL `vip3_clone_soo_boots`(1195,104511,4)$$
-- Druid: feral, balance, restoration, guardian.
CALL `vip3_clone_soo_boots`(1196,104428,1024)$$
CALL `vip3_clone_soo_boots`(1197,104435,1024)$$
CALL `vip3_clone_soo_boots`(1198,104471,1024)$$
CALL `vip3_clone_soo_boots`(1199,104488,1024)$$
-- Death knight: frost/unholy, blood.
CALL `vip3_clone_soo_boots`(1200,104567,32)$$
CALL `vip3_clone_soo_boots`(1201,104592,32)$$

-- Explicit SoO appearance sources for every VIP3 weapon/off-hand.
CALL `vip3_pin_soo_display`(990217,104401,2,7)$$  -- Hellscream's Doomblade
CALL `vip3_pin_soo_display`(990218,104402,2,4)$$  -- Hellscream's Warmace
CALL `vip3_pin_soo_display`(990219,104404,2,0)$$  -- Hellscream's Cleaver
CALL `vip3_pin_soo_display`(990220,104400,2,15)$$ -- Hellscream's Razor
CALL `vip3_pin_soo_display`(990221,104434,2,13)$$ -- Softfoot's Last Resort
CALL `vip3_pin_soo_display`(990222,104407,4,6)$$  -- Hellscream's Shield Wall
CALL `vip3_pin_soo_display`(990223,104408,4,0)$$  -- Hellscream's Tome of Destruction
CALL `vip3_pin_soo_display`(990224,104401,2,7)$$  -- off-hand sword appearance
CALL `vip3_pin_soo_display`(990225,104406,2,10)$$ -- Hellscream's War Staff
CALL `vip3_pin_soo_display`(990226,104483,2,8)$$  -- Greatsword of Pride's Fall
CALL `vip3_pin_soo_display`(990227,104559,2,5)$$  -- Gar'tok, Strength of the Faithful
CALL `vip3_pin_soo_display`(990228,104403,2,6)$$  -- Hellscream's Pig Sticker
CALL `vip3_pin_soo_display`(990229,104399,2,2)$$  -- Hellscream's Warbow
CALL `vip3_pin_soo_display`(990230,104563,2,3)$$  -- Kor'kron Hand Cannon
CALL `vip3_pin_soo_display`(990231,104598,2,19)$$ -- Immaculately Preserved Wand

-- Idempotently rebuild only this update's 23 boot offers.
DELETE FROM `npc_vendor`
 WHERE `entry` = 990902
   AND `item` IN
       (991005,991015,991025,991035,991045,991055,991065,991075,
        991085,991095,991105,991115,991125,991135,991145,991155,
        991165,991175,991185,991195,991205,991215,991225)$$

CALL `vip3_vendor_link_soo`(991005)$$
CALL `vip3_vendor_link_soo`(991015)$$
CALL `vip3_vendor_link_soo`(991025)$$
CALL `vip3_vendor_link_soo`(991035)$$
CALL `vip3_vendor_link_soo`(991045)$$
CALL `vip3_vendor_link_soo`(991055)$$
CALL `vip3_vendor_link_soo`(991065)$$
CALL `vip3_vendor_link_soo`(991075)$$
CALL `vip3_vendor_link_soo`(991085)$$
CALL `vip3_vendor_link_soo`(991095)$$
CALL `vip3_vendor_link_soo`(991105)$$
CALL `vip3_vendor_link_soo`(991115)$$
CALL `vip3_vendor_link_soo`(991125)$$
CALL `vip3_vendor_link_soo`(991135)$$
CALL `vip3_vendor_link_soo`(991145)$$
CALL `vip3_vendor_link_soo`(991155)$$
CALL `vip3_vendor_link_soo`(991165)$$
CALL `vip3_vendor_link_soo`(991175)$$
CALL `vip3_vendor_link_soo`(991185)$$
CALL `vip3_vendor_link_soo`(991195)$$
CALL `vip3_vendor_link_soo`(991205)$$
CALL `vip3_vendor_link_soo`(991215)$$
CALL `vip3_vendor_link_soo`(991225)$$

DROP PROCEDURE IF EXISTS `vip3_vendor_link_soo`$$
DROP PROCEDURE IF EXISTS `vip3_pin_soo_display`$$
DROP PROCEDURE IF EXISTS `vip3_clone_soo_boots`$$

DELIMITER ;

SET SESSION GROUP_CONCAT_MAX_LEN = @VIP3_SOO_OLD_GROUP_CONCAT_MAX_LEN;
SET SQL_SAFE_UPDATES = @VIP3_SOO_OLD_SQL_SAFE_UPDATES;

-- Expected: 23 SoO boot variants, 15 pinned SoO weapon/off-hand displays and
-- 161 total VIP3 vendor offers (115 T16 + 23 boots + 23 support/weapon items).
SELECT COUNT(*) AS `vip3_soo_boots`
  FROM `item_template`
 WHERE `entry` IN
       (991005,991015,991025,991035,991045,991055,991065,991075,
        991085,991095,991105,991115,991125,991135,991145,991155,
        991165,991175,991185,991195,991205,991215,991225)
   AND `InventoryType` = 8
   AND `itemset` = 0;
SELECT COUNT(*) AS `vip3_soo_weapon_displays`
  FROM `item_template`
 WHERE `entry` BETWEEN 990217 AND 990231
   AND `displayid` IN
       (127170,127167,127165,127164,125309,126307,127465,127169,
        125007,125041,127166,127163,124558,127684);
SELECT COUNT(*) AS `vip3_vendor_items`
  FROM `npc_vendor`
 WHERE `entry` = 990902;
