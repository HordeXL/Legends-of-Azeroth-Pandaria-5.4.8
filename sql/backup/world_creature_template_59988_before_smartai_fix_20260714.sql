-- Revert quest 29792 Ji Firepaw (entry 59988) to the state captured before
-- 2026_07_14_04_world_quest_29792_restore_ji_smartai.sql.
UPDATE `creature_template`
SET `AIName` = 'SmartAI',
    `ScriptName` = 'npc_ji_forest_escort'
WHERE `entry` = 59988;
