-- Roll back 2026_07_21_00_world_fix_item_loot_container_flags.sql.
-- Restore only the three exact pre-change Flags values. Item templates and
-- their loot rows remain present.

START TRANSACTION;

UPDATE `item_template` AS `i`
SET `i`.`Flags` = CASE `i`.`entry`
    WHEN 98134 THEN 0
    WHEN 98546 THEN 0
    WHEN 104014 THEN 4096
    ELSE `i`.`Flags`
END
WHERE `i`.`entry` IN (98134, 98546, 104014)
  AND `i`.`class` = 15
  AND `i`.`Quality` = 4
  AND `i`.`FlagsExtra` = 8192
  AND ((`i`.`entry` = 98134
        AND `i`.`name` = 'Heroic Cache of Treasures'
        AND `i`.`Flags` = 4
        AND `i`.`spellid_1` = 142397)
    OR (`i`.`entry` = 98546
        AND `i`.`name` = 'Bulging Heroic Cache of Treasures'
        AND `i`.`Flags` = 4
        AND `i`.`spellid_1` = 142901)
    OR (`i`.`entry` = 104014
        AND `i`.`name` = 'Pouch of Timeless Coins'
        AND `i`.`Flags` = 4100
        AND `i`.`spellid_1` = 147598))
  AND EXISTS (
      SELECT 1
      FROM `item_loot_template` AS `l`
      WHERE `l`.`entry` = `i`.`entry`
  );

COMMIT;
