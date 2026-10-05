-- Restore the faction portal rooms in Northrend Dalaran (map 571).
-- Stormwind (190960), Orgrimmar (191009), and Caverns of Time (193604) already spawn.
-- Use the existing Dalaran portal templates and their original room positions.
INSERT INTO `gameobject`
    (`id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `phaseId`, `phaseGroup`,
     `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`,
     `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `ScriptName`, `VerifiedBuild`)
SELECT p.id, 571, 4395, p.areaId, 1, 65535, 0, 0,
       p.x, p.y, p.z, p.o, 0, 0, p.r2, p.r3, 600, 0, 1, '', 0
FROM (
    SELECT 191006 AS id, 4740 AS areaId, 5706.16 AS x, 730.102 AS y, 641.745 AS z, -0.820303 AS o, -0.398748 AS r2, 0.917060 AS r3 -- Darnassus
    UNION ALL SELECT 191007, 4740, 5699.58, 735.469, 641.769,  2.024580,  0.848048, 0.529920 -- Exodar
    UNION ALL SELECT 191008, 4740, 5712.68, 724.845, 641.736,  0.890117,  0.430511, 0.902586 -- Ironforge
    UNION ALL SELECT 191013, 4740, 5697.49, 744.912, 641.819, -0.663223, -0.325567, 0.945519 -- Shattrath (Alliance)
    UNION ALL SELECT 191010, 4616, 5946.98, 568.479, 640.573,  1.605700,  0.719339, 0.694659 -- Silvermoon
    UNION ALL SELECT 191011, 4616, 5945.81, 577.357, 640.574,  1.797690,  0.782608, 0.622514 -- Thunder Bluff
    UNION ALL SELECT 191012, 4616, 5934.66, 590.688, 640.575, -1.605700, -0.719339, 0.694659 -- Undercity
    UNION ALL SELECT 191014, 4616, 5941.66, 584.887, 640.574,  0.331611,  0.165047, 0.986286 -- Shattrath (Horde)
) AS p
WHERE NOT EXISTS (
    SELECT 1 FROM `gameobject` AS existing
    WHERE existing.`id` = p.id AND existing.`map` = 571
);
