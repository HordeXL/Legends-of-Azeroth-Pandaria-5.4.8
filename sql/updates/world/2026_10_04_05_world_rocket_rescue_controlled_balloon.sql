-- Rocket Rescue: use the controllable vehicle record directly on the moving
-- balloon.  This preserves the working scripted spline and exposes the quest
-- action bar without a nested vehicle blocking the parent movement.

START TRANSACTION;

DELETE FROM `vehicle_template_accessory`
WHERE `entry` = 40505 AND `accessory_entry` = 40511;

UPDATE `creature_template`
SET `VehicleId` = 752,
    `spell1` = 75560,
    `spell2` = 73257,
    `spell6` = 75991,
    `ScriptName` = 'npc_steamwheedle_balloon_escort'
WHERE `entry` = 40505;

COMMIT;
