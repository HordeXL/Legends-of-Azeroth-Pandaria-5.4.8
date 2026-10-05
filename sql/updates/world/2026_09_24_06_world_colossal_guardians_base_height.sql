-- Colossal Guardians: vehicle bases must be above the terrain lookup surface.
-- Sun base was 5.44 yards below terrain. When loaded with a saved respawn time,
-- Creature::LoadFromDB relocates flying creatures to GetHeight(..., false).
-- Below-terrain lookup returns INVALID_HEIGHT (-200000); InstallAccessory then
-- asserts because the guardian cannot be created at that invalid position.
-- Use the existing authored landing heights, verified against installed maps:
-- Sun terrain 87.2436981, Moon terrain 95.7466736. Preserve X/Y and orientation.
UPDATE `creature` SET `position_z` = 87.3271
WHERE `guid` = 291094 AND `id` = 46024 AND `map` = 1
  AND ABS(`position_z` - 81.8009) < 0.01;
UPDATE `creature` SET `position_z` = 95.8086
WHERE `guid` = 291105 AND `id` = 46087 AND `map` = 1
  AND ABS(`position_z` - 94.1961) < 0.01;
