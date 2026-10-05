-- Relocate the existing Captain Doren spawn to the Den of Defiance quest
-- area next to Doren's Logs (GO 215844, spawn 501561). The old position was
-- about 90 yards away and 33 yards lower. Do not create a duplicate boss.
-- Installed map geometry at (2526, -477) reports ground Z 341.122467.
UPDATE `creature`
SET `position_x` = 2526.0, `position_y` = -477.0,
    `position_z` = 341.122467, `orientation` = 1.57
WHERE `guid` = 501677 AND `id` = 66052 AND `map` = 870;
