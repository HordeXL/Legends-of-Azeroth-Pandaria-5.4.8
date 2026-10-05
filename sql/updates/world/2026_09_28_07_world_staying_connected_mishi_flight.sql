-- Staying Connected (30795): restore Mishi's missing Valley of Emperors flight gossip.
UPDATE `creature_template`
SET `ScriptName` = 'npc_mishi_staying_connected'
WHERE `entry` = 60796;
