-- Canyon Chase (12143 Alliance / 12145 Horde): start the missing forager chase
-- on quest accept and allow an active player to restart it at the questgiver.
UPDATE `creature_template`
SET `AIName` = '', `ScriptName` = 'npc_canyon_chase_questgiver'
WHERE `entry` IN (26978, 26979);
