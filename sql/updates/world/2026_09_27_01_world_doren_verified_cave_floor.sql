-- Supersedes update 00: Doren's Logs was not a reliable cave anchor.
-- Vmap confirms the actual Den of Defiance floor at (2540, -354) is
-- Z 343.679535, beneath terrain Z 391.105286. Nearby player and Taran Zhu
-- positions also have matching vmap floor hits inside this cave.
-- A saved curhealth of zero loads the template's full maximum health.
UPDATE `creature`
SET `position_x` = 2540.0, `position_y` = -354.0,
    `position_z` = 343.679535, `orientation` = 4.71, `curhealth` = 0
WHERE `guid` = 501677 AND `id` = 66052 AND `map` = 870;
