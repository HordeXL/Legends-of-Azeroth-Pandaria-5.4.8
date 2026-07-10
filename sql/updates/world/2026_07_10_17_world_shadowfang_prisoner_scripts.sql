-- Classic Shadowfang Keep prisoners: Deathstalker Adamant and Sorcerer Ashcrombe.
-- npc_escortAI consumes each existing authentic 14-row script_waypoint path.
UPDATE `creature_template`
SET `AIName`='', `ScriptName`='npc_shadowfang_prisoner'
WHERE `entry` IN (3849,3850);
