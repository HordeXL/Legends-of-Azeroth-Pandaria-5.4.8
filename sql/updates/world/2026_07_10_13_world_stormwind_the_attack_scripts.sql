-- Quest 434: The Attack!
-- C++ implementation restored in zone_stormwind_city.cpp.  Keep both
-- script_waypoint paths: this core's npc_escortAI loads them directly.
UPDATE `creature_template` SET `AIName`='', `ScriptName`='npc_lord_gregor_lescovar' WHERE `entry`=1754;
UPDATE `creature_template` SET `AIName`='', `ScriptName`='npc_marzon_silent_blade' WHERE `entry`=1755;
UPDATE `creature_template` SET `AIName`='', `ScriptName`='npc_tyrion' WHERE `entry`=7766;
UPDATE `creature_template` SET `AIName`='', `ScriptName`='npc_tyrion_spybot' WHERE `entry`=8856;
