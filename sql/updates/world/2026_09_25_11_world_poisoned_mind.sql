-- The Poisoned Mind (31211): boarding gossip and private bombing vehicle.
-- Requires matching quest_poisoned_mind.cpp. No permanent targets are added.
UPDATE `creature_template` SET `npcflag`=`npcflag`|1, `ScriptName`='npc_xaril_poisoned_mind'
WHERE `entry`=62151 AND `AIName`='' AND `ScriptName` IN ('','npc_xaril_poisoned_mind');
UPDATE `creature_template`
SET `VehicleId`=156, `spell1`=124201, `spell2`=126308, `spell3`=124206,
    `ScriptName`='npc_poisoned_mind_flyer'
WHERE `entry`=63675 AND `AIName`='' AND `ScriptName` IN ('','npc_poisoned_mind_flyer');
