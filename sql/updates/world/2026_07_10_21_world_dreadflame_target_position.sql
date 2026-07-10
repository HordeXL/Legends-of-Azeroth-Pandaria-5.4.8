-- Dreadflame (100679) uses its database destination on effect 0 in the
-- matching TrinityCore 4.3.4 data.  The imported effect-2 row is rejected
-- by this core because that effect has no TARGET_DEST_DB target.
UPDATE `spell_target_position`
SET `effIndex` = 0
WHERE `id` = 100679
  AND `effIndex` = 2
  AND `target_map` = 720;
