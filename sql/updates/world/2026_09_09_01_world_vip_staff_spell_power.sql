-- Give universal VIP two-hand staves the same Spell Power budget as VIP wands.
-- All ten stat slots are occupied: replace Parry (slot 7), retaining Strength,
-- Agility, Intellect, Spirit, Stamina, Dodge, Crit, Haste and Mastery.
-- This trades the staff's Parry contribution for caster/healer usefulness.
-- Preserve weapon damage, sockets, appearances and existing item IDs.
-- Absolute values fit signed SMALLINT and are safe to apply repeatedly.
-- Restart worldserver after applying so equipped items use the new templates.
UPDATE `item_template`
   SET `stat_type7` = 45,
       `stat_value7` = CASE `entry`
           WHEN 990025 THEN 9000
           WHEN 990125 THEN 16000
           WHEN 990225 THEN 30000
       END
 WHERE `entry` IN (990025, 990125, 990225)
   AND `class` = 2 AND `subclass` = 10 AND `InventoryType` = 17;
