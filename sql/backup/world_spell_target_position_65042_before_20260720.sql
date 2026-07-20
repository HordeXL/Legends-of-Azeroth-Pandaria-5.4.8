-- Exact rollback for 2026_07_20_07_world_fix_ulduar_prison_teleport_target.sql.
UPDATE `spell_target_position`
SET `effIndex` = 2
WHERE `id` = 65042
  AND `effIndex` = 0
  AND `target_map` = 603
  AND ABS(`target_position_x` - 1855.07) < 0.001
  AND ABS(`target_position_y` - (-11.4879)) < 0.001
  AND ABS(`target_position_z` - 334.559) < 0.001
  AND ABS(`target_orientation` - 5.53269) < 0.001;
