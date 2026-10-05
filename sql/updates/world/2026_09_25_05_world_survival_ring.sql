-- Survival Ring: Flame (30240) and Blades (30242), 5.4.8 sixty-second trials.
-- Both challenges share the existing ring/controller and trainers.
UPDATE `creature_template` SET `ScriptName`='npc_survival_ring_controller'
WHERE `entry`=58953 AND `AIName`='' AND `ScriptName`='';
UPDATE `creature_template` SET `ScriptName`='npc_survival_ring_trainer'
WHERE `entry`=58744 AND `AIName`='' AND `ScriptName`='';
INSERT INTO `spell_script_names` (`spell_id`,`ScriptName`)
SELECT 112836,'spell_survival_ring_progress' WHERE NOT EXISTS
(SELECT 1 FROM `spell_script_names` WHERE `spell_id`=112836 AND `ScriptName`='spell_survival_ring_progress');
INSERT INTO `spell_script_names` (`spell_id`,`ScriptName`)
SELECT 127386,'spell_survival_ring_progress' WHERE NOT EXISTS
(SELECT 1 FROM `spell_script_names` WHERE `spell_id`=127386 AND `ScriptName`='spell_survival_ring_progress');
INSERT INTO `spell_script_names` (`spell_id`,`ScriptName`)
SELECT 112041,'spell_survival_ring_firework' WHERE NOT EXISTS
(SELECT 1 FROM `spell_script_names` WHERE `spell_id`=112041 AND `ScriptName`='spell_survival_ring_firework');
