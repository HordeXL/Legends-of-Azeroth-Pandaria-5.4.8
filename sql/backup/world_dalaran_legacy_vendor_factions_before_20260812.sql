-- Exact rollback for
-- 2026_08_12_00_world_fix_dalaran_legacy_vendor_factions.sql.
--
-- This restores only Kylo Kelwin (69318) and Herwin Steampop (69321) from
-- neutral faction 35 to their inherited, but incorrect, hostile faction 14.
UPDATE `creature_template`
SET `faction` = 14
WHERE `entry` IN (69318, 69321)
  AND `faction` = 35;
