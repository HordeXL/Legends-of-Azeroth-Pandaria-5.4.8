-- Rocket Rescue: vehicle 751 already provides the player casting seat.
-- Remove the nested vehicle accessory, which leaves the player behind and
-- corrupts the camera when the outer balloon follows its flight spline.

START TRANSACTION;

DELETE FROM `vehicle_template_accessory`
WHERE `entry` = 40505 AND `accessory_entry` = 40511;

UPDATE `creature_template`
SET `spell1` = 75560,
    `spell2` = 73257,
    `spell6` = 75991
WHERE `entry` = 40505;

COMMIT;
