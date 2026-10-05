-- What Lies Beneath (30827): restore Yalia's ritual gossip and the three
-- sequential totem interactions. The final totem summons the personal Sha
-- encounter; killing it awards the Ritual completed objective.

UPDATE `creature_template`
SET `ScriptName` = 'npc_yalia_what_lies_beneath'
WHERE `entry` = 60864;

UPDATE `creature_template`
SET `npcflag` = `npcflag` | 1,
    `AIName` = '',
    `ScriptName` = 'npc_what_lies_beneath_totem'
WHERE `entry` IN (60933, 60990, 60991);

UPDATE `creature_template`
SET `ScriptName` = 'npc_what_lies_beneath_sha'
WHERE `entry` = 61024;

-- Remove the old SmartAI click-credit rows. The C++ script validates the
-- quest, enforces retail order and permits recovery if the last summon expires.
DELETE FROM `smart_scripts`
WHERE `source_type` = 0
  AND `entryorguid` IN (60933, 60990, 60991);
