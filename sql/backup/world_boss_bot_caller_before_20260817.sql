-- Pre-change audit for the first Boss Bot Caller stage.
-- Verified against the active `world` database on 2026-08-17:
--   creature_template entry 990912 did not exist;
--   creature spawn GUID 4000096 did not exist;
--   table playerbot_world_boss_caller did not exist.
-- This is an absence record, not a rollback patch. The user's full world backup
-- remains the recovery source if the new isolated custom rows must be removed.

SELECT * FROM `creature_template` WHERE `entry` = 990912;
SELECT * FROM `creature_template_model` WHERE `CreatureID` = 990912;
SELECT * FROM `creature` WHERE `guid` = 4000096 OR `id` = 990912;

