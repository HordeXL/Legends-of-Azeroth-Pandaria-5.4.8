-- The Savior of Stoneplow (30627): Miss Fanny was missing both her gossip
-- NPC flag and the script that supplies the quest-only start option.
UPDATE `creature_template`
SET `npcflag` = `npcflag` | 1,
    `ScriptName` = 'npc_vfw_miss_fanny'
WHERE `entry` = 59857;
