-- Restore playable Kiryn control for Scouting Report: On the Right Track (29731).
-- Requires matching rebuilt server scripts. Vehicle 238 uses seat 2242:
-- hidden passenger, control and vehicle spell UI, with zero attachment offsets.
START TRANSACTION;
UPDATE `creature_template`
SET `npcflag`=`npcflag` | 3,`unit_flags`=`unit_flags` | 512,
    `AIName`='',`ScriptName`='npc_jade_forest_right_track_report'
WHERE `entry`=55646;
UPDATE `creature` SET `unit_flags`=`unit_flags` | 512 WHERE `id`=55646;
UPDATE `creature_template`
SET `VehicleId`=238,`spell1`=104380,`spell2`=0,`spell3`=0,`spell4`=0,
    `faction`=35,`AIName`='',`ScriptName`='npc_jade_forest_right_track_kiryn'
WHERE `entry`=55680;
DELETE FROM `spell_script_names` WHERE `spell_id`=104380 AND `ScriptName`='spell_jade_forest_right_track_smoke';
INSERT INTO `spell_script_names` (`spell_id`,`ScriptName`)
VALUES (104380,'spell_jade_forest_right_track_smoke');
COMMIT;
