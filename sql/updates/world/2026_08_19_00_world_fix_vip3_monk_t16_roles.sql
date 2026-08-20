-- Correct the two swapped Monk T16 role labels in the VIP3 vendor.
--
-- Local build-18414 ItemSet.dbc is authoritative here:
--   1191 -> Brewmaster bonuses 145049/145055
--   1192 -> Mistweaver bonuses 145439/145449
--   1193 -> Windwalker bonuses 145004/145022
-- The authentic ItemSet IDs were already preserved. Only the Tank/DPS labels
-- for the 1191 and 1193 blocks were reversed, which made a player selecting
-- the item named "DPS" receive Brewmaster bonuses.

UPDATE `item_template`
   SET `name` = CONCAT(
       'VIP3 PvE Tank ',
       CASE
         WHEN `name` LIKE 'VIP3 PvE DPS %'  THEN SUBSTRING(`name`, 14)
         WHEN `name` LIKE 'VIP3 PvE Tank %' THEN SUBSTRING(`name`, 15)
         WHEN `name` LIKE 'VIP3 PvE %'      THEN SUBSTRING(`name`, 10)
         ELSE `name`
       END)
 WHERE `entry` BETWEEN 991120 AND 991127;

UPDATE `item_template`
   SET `name` = CONCAT(
       'VIP3 PvE DPS ',
       CASE
         WHEN `name` LIKE 'VIP3 PvE Tank %' THEN SUBSTRING(`name`, 15)
         WHEN `name` LIKE 'VIP3 PvE DPS %'  THEN SUBSTRING(`name`, 14)
         WHEN `name` LIKE 'VIP3 PvE %'      THEN SUBSTRING(`name`, 10)
         ELSE `name`
       END)
 WHERE `entry` BETWEEN 991140 AND 991147;

-- Guarded verification: five genuine set pieces plus three non-set matching
-- appearance pieces must remain in each corrected role block.
SELECT
    SUM(`entry` BETWEEN 991120 AND 991124 AND `itemset` = 1191 AND
        `name` LIKE 'VIP3 PvE Tank %') AS `monk_brewmaster_t16_pieces`,
    SUM(`entry` BETWEEN 991140 AND 991144 AND `itemset` = 1193 AND
        `name` LIKE 'VIP3 PvE DPS %') AS `monk_windwalker_t16_pieces`,
    SUM(`entry` BETWEEN 991125 AND 991127 AND `itemset` = 0 AND
        `name` LIKE 'VIP3 PvE Tank %') AS `monk_brewmaster_nonset_pieces`,
    SUM(`entry` BETWEEN 991145 AND 991147 AND `itemset` = 0 AND
        `name` LIKE 'VIP3 PvE DPS %') AS `monk_windwalker_nonset_pieces`
FROM `item_template`
WHERE `entry` BETWEEN 991120 AND 991147;
