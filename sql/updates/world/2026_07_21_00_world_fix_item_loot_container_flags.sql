-- Restore ITEM_FLAG_HAS_LOOT (0x4) on three genuine Build-18414 loot
-- containers. Matching SkyFire 5.4.8 SFDB 24.001 has this bit set on all
-- three items, while the preserved local base accidentally omits it.
-- The item templates and every loot row are preserved; nothing is deleted.

START TRANSACTION;

UPDATE `item_template` AS `i`
SET `i`.`Flags` = `i`.`Flags` | 4
WHERE `i`.`entry` IN (98134, 98546, 104014)
  AND `i`.`class` = 15
  AND `i`.`Quality` = 4
  AND `i`.`FlagsExtra` = 8192
  AND (`i`.`Flags` & 4) = 0
  AND ((`i`.`entry` = 98134
        AND `i`.`name` = 'Heroic Cache of Treasures'
        AND `i`.`Flags` = 0
        AND `i`.`spellid_1` = 142397)
    OR (`i`.`entry` = 98546
        AND `i`.`name` = 'Bulging Heroic Cache of Treasures'
        AND `i`.`Flags` = 0
        AND `i`.`spellid_1` = 142901)
    OR (`i`.`entry` = 104014
        AND `i`.`name` = 'Pouch of Timeless Coins'
        AND `i`.`Flags` = 4096
        AND `i`.`spellid_1` = 147598))
  AND EXISTS (
      SELECT 1
      FROM `item_loot_template` AS `l`
      WHERE `l`.`entry` = `i`.`entry`
  );

COMMIT;
