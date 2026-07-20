-- Prison of Yogg-Saron Teleport (65042) is part of the same database-targeted
-- Ulduar teleporter group as spells 64014/64024/64025/64028-64032.
-- Matching SkyFire 5.4.8 code assigns TARGET_DEST_DB to effect 0, and its
-- matching 5.4.8 world data stores this destination on effect 0.  Preserve the
-- destination and repair only the stale imported effect key.
UPDATE `spell_target_position`
SET `effIndex` = 0
WHERE `id` = 65042
  AND `effIndex` = 2
  AND `target_map` = 603
  AND ABS(`target_position_x` - 1855.07) < 0.001
  AND ABS(`target_position_y` - (-11.4879)) < 0.001
  AND ABS(`target_position_z` - 334.559) < 0.001
  AND ABS(`target_orientation` - 5.53269) < 0.001;
