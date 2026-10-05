-- Remove an invisible hostile Alliance soldier erroneously spawned beside the
-- Grookin Hill scouting-report NPCs. Scouting Report: On the Right Track uses
-- the separate Young Alliance Soldier entry 55770 at the Serpent's Heart.
START TRANSACTION;
DELETE FROM `creature_addon` WHERE `guid`=503687;
DELETE FROM `creature` WHERE `guid`=503687 AND `id`=55828;
COMMIT;
