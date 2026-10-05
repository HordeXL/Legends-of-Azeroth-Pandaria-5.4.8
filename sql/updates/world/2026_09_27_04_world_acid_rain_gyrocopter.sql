-- Reconstructed Acid Rain vehicle flight; requires matching C++ scripts.
-- The existing helicopter near Kiryn boards a private summoned vehicle.
START TRANSACTION;
UPDATE `creature_template`
SET `npcflag`=1, `faction`=35, `AIName`='',
    `ScriptName`='npc_jade_forest_acid_rain_boarding'
WHERE `entry` IN (55674,55675);
UPDATE `creature_template`
SET `VehicleId`=6, `npcflag`=0, `faction`=35,
    `unit_flags`=`unit_flags` | 768, `AIName`='',
    `spell1`=104463, `spell2`=104527,
    `ScriptName`='npc_jade_forest_acid_rain_flight'
WHERE `entry`=55676;

-- Keep the boarding helicopter beside the quest giver, in the shared phase.
UPDATE `creature` SET `phaseMask`=1, `phaseId`=0, `phaseGroup`=0,
    `position_x`=2510.05, `position_y`=-485.792, `position_z`=341.653
WHERE `guid`=501672 AND `id`=55674 AND `map`=870;

DELETE FROM `creature_template_movement` WHERE `CreatureId`=55676;
INSERT INTO `creature_template_movement`
(`CreatureId`,`Ground`,`Swim`,`Flight`,`Rooted`)
VALUES (55676,0,0,1,0);

DELETE FROM `spell_script_names`
WHERE (`spell_id`=104464 AND `ScriptName`='spell_jade_forest_acid_rain_star')
   OR (`spell_id`=104527 AND `ScriptName`='spell_jade_forest_acid_rain_blossom');
INSERT INTO `spell_script_names` (`spell_id`,`ScriptName`) VALUES
(104464,'spell_jade_forest_acid_rain_star'),
(104527,'spell_jade_forest_acid_rain_blossom');
COMMIT;
