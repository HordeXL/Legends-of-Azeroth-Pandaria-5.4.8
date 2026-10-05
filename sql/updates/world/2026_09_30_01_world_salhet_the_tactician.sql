-- Salhet the Tactician (28277): restore the missing gossip handler on Salhet.
UPDATE `creature_template`
SET `ScriptName` = 'npc_salhet_tactician'
WHERE `entry` = 48237;
