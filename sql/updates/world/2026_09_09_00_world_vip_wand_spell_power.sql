-- VIP caster wands need weapon Spell Power in addition to Intellect.
-- All ten item stat slots are occupied. Replace only Strength (slot 2),
-- preserving the other nine stats, weapon damage, sockets and appearances.
-- Custom test-gear budget: 10 times the rank's base hybrid stat (900/1600/3000).
-- Each value fits the signed SMALLINT stat_value2 column (maximum 32767).
-- Absolute assignments make this migration safe to apply repeatedly.
-- Restart worldserver after applying so equipped items use the new templates.
UPDATE `item_template`
   SET `stat_type2` = 45,
       `stat_value2` = CASE `entry`
           WHEN 990031 THEN 9000
           WHEN 990131 THEN 16000
           WHEN 990231 THEN 30000
       END
 WHERE `entry` IN (990031, 990131, 990231)
   AND `class` = 2 AND `subclass` = 19 AND `InventoryType` = 26;
