-- Paint it Red! (31765): Thunder Hold Cannons are destructible quest targets.
-- Keep them attackable for kill credit, but prevent all outgoing attacks.
UPDATE `creature_template`
SET `AIName`='PassiveAI', `unit_flags`=`unit_flags` | 131072
WHERE `entry`=66203 AND `ScriptName`='' AND `AIName` IN ('','PassiveAI');
