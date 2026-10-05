-- Chains of the Anub'ar (12064): Anok'ra and Tivax were stored below the
-- accessible Icemist Village terrain. Move the existing unique spawns onto
-- the village floor so all three key-fragment targets can be reached.

UPDATE `creature`
SET `position_x` = 3968.0,
    `position_y` = 2233.0,
    `position_z` = 153.6,
    `orientation` = 3.28,
    `spawnMask` = 1,
    `phaseMask` = 1,
    `phaseId` = 0,
    `phaseGroup` = 0,
    `spawntimesecs` = 60
WHERE `guid` = 117626 AND `id` = 26769;

UPDATE `creature`
SET `position_x` = 4075.0,
    `position_y` = 2260.0,
    `position_z` = 152.8,
    `orientation` = 3.56,
    `spawnMask` = 1,
    `phaseMask` = 1,
    `phaseId` = 0,
    `phaseGroup` = 0,
    `spawntimesecs` = 60
WHERE `guid` = 117627 AND `id` = 26770;
