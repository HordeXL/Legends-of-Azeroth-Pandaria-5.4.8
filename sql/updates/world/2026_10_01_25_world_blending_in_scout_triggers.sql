-- Blending In (11633)
--
-- The three invisible Temple trigger creatures were missing from En'kilah.
-- Their existing SmartAI casts the matching quest-credit spell when the
-- player approaches, but without these spawns none of the objectives could
-- progress.

START TRANSACTION;

DELETE FROM `creature`
WHERE `id` IN (25471, 25472, 25473);

INSERT INTO `creature`
(`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `phaseId`,
 `phaseGroup`, `modelid`, `equipment_id`, `position_x`, `position_y`,
 `position_z`, `orientation`, `spawntimesecs`, `spawntimesecs_max`,
 `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`,
 `npcflag`, `npcflag2`, `unit_flags`, `unit_flags2`, `dynamicflags`,
 `ScriptName`, `walk_mode`, `VerifiedBuild`)
VALUES
(4000146, 25471, 571, 3537, 4136, 1, 1, 0, 0, 0, 0,
 4111.14, 3734.87, 91.8481, 3.9968, 180, 0, 0, 0, 1, 0, 0,
 0, 0, 0, 0, 0, '', 0, 0),
(4000147, 25472, 571, 3537, 4135, 1, 1, 0, 0, 0, 0,
 4094.38, 3493.95, 131.75, 0.767945, 180, 0, 0, 0, 1, 0, 0,
 0, 0, 0, 0, 0, '', 0, 0),
(4000148, 25473, 571, 3537, 4137, 1, 1, 0, 0, 0, 0,
 3791.67, 3425.03, 83.8943, 0.506145, 300, 0, 0, 0, 8982, 3155, 0,
 0, 0, 0, 0, 0, '', 0, 0);

COMMIT;
