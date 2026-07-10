-- The matching 4.3.4 row uses effect 0, but startup validation proved that
-- effect 0 also lacks TARGET_DEST_DB in this core's 5.4.8 spell data.
-- Restore the original imported row until a matching 5.4.8 source is found.
UPDATE `spell_target_position`
SET `effIndex` = 2
WHERE `id` = 100679
  AND `effIndex` = 0
  AND `target_map` = 720;
