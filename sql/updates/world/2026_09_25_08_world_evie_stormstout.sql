-- Evie Stormstout (31077): meet Chen and listen to his eulogy.
-- Requires the matching zone_dread_wastes.cpp code update.
UPDATE `creature_template` SET `ScriptName`='npc_chen_evie_eulogy'
WHERE `entry`=67138 AND `AIName`='' AND `ScriptName`='';
