-- The Defense of Nahom (28501): make the Ramkahen Sergeants interactive and
-- route their gossip through the quest-credit fallback in zone_uldum.cpp.
UPDATE `creature_template`
SET `npcflag` = `npcflag` | 1,
    `ScriptName` = 'npc_ramkahen_sergeant'
WHERE `entry` = 49228;
