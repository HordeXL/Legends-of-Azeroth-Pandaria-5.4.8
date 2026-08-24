-- Adapted from ProjectSkyfire/SkyFire_548 commit d16f17f9c for this core's
-- combined lfg_dungeon_template schema. Fix Scarlet Halls and add the
-- Headless Horseman destination without replacing unrelated LFG rows.

INSERT INTO `lfg_dungeon_template`
    (`dungeonId`, `name`, `position_x`, `position_y`, `position_z`, `orientation`, `requiredItemLevel`)
VALUES
    (163, 'Scarlet Halls',         820.743, 607.812, 13.6389, 0.0000, 0),
    (164, 'Scarlet Monastery',    1124.640, 512.467,  0.989549, 1.5708, 0),
    (285, 'The Headless Horseman',1124.640, 512.467,  0.989549, 1.5708, 0)
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`),
    `position_x` = VALUES(`position_x`),
    `position_y` = VALUES(`position_y`),
    `position_z` = VALUES(`position_z`),
    `orientation` = VALUES(`orientation`),
    `requiredItemLevel` = VALUES(`requiredItemLevel`);
