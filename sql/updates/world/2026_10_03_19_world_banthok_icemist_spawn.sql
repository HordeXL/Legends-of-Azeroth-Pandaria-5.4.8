-- Chains of the Anub'ar (12064): Banthok Icemist's only spawn was placed at
-- the far northern edge of Icemist Village, outside the active quest area.
-- Move him onto known-good village terrain near the other quest actors.

UPDATE `creature`
SET `position_x` = 4032.0,
    `position_y` = 2300.0,
    `position_z` = 153.8,
    `orientation` = 4.78,
    `spawnMask` = 1,
    `phaseMask` = 1,
    `phaseId` = 0,
    `phaseGroup` = 0,
    `spawntimesecs` = 60,
    `MovementType` = 0,
    `wander_distance` = 0
WHERE `guid` = 117553 AND `id` = 26733;
