-- Han Stormstout (31078): enable explicit inspection and objective credit.
-- Requires the matching C++ script. Leave later story variants unchanged.
UPDATE `creature_template` SET `npcflag`=`npcflag`|1, `ScriptName`='npc_han_stormstout_quest'
WHERE `entry`=62776 AND `AIName`='' AND `ScriptName` IN ('','npc_han_stormstout_quest');
