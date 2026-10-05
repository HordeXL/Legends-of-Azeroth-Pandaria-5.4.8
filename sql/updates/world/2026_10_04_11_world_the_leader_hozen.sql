-- Quest 30612, The Leader Hozen: restore the missing Tassle -> Chomp Chomp ->
-- Ook of Dook arena event. Both Tassle entries can start it, while the combat
-- copy of Ook remains hidden and unattackable until the sequence reaches him.
UPDATE `creature_template`
SET `ScriptName` = 'npc_tassle_leader_hozen'
WHERE `entry` IN (59661, 60212);

UPDATE `creature_template`
SET `ScriptName` = 'npc_ook_of_dook_leader_hozen'
WHERE `entry` = 60188;
