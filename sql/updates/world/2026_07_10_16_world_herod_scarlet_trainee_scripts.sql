-- Classic Scarlet Monastery (map 189): Herod and Scarlet Trainees.
-- npc_escortAI consumes the existing 12-row script_waypoint path directly.
UPDATE `creature_template` SET `AIName`='', `ScriptName`='boss_herod' WHERE `entry`=3975;
UPDATE `creature_template` SET `AIName`='', `ScriptName`='npc_scarlet_trainee' WHERE `entry`=6575;
