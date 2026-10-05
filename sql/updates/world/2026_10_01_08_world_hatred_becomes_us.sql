-- Hatred Becomes Us (30783): the quest item summons Totem of Harmony 61062.
-- The totem must exorcise a nearby crazed ranger, not acquire ordinary hostile
-- wildlife. Each ranger now creates its own player-tagged Seething Hatred.

UPDATE `creature_template`
SET `faction` = 7,
    `AIName` = '',
    `ScriptName` = 'npc_crazed_shado_pan_ranger'
WHERE `entry` = 61050;

UPDATE `creature_template`
SET `AIName` = '',
    `ScriptName` = 'npc_totem_of_harmony_30783'
WHERE `entry` = 61062;

UPDATE `creature_template`
SET `AIName` = '',
    `ScriptName` = 'npc_hatred_becomes_us_sha'
WHERE `entry` = 61054;

DELETE FROM `smart_scripts`
WHERE `source_type` = 0 AND `entryorguid` = 61050;

-- These are encounter creatures and must be summoned by a ranger (61054) or
-- by the player's hatred mechanic (61092). Static copies caused the reported
-- kite/credit trap and could be killed without purifying a ranger.
DELETE FROM `creature`
WHERE `id` IN (61054, 61092);
