-- Rocket Rescue: restore the controllable throwing station.  The core now
-- relocates passengers of nested vehicle accessories together with the outer
-- balloon, so the station supplies its intended quest spell bar without
-- leaving the player or camera behind.

START TRANSACTION;

DELETE FROM `vehicle_template_accessory`
WHERE `entry` = 40505 AND `accessory_entry` = 40511;

INSERT INTO `vehicle_template_accessory`
    (`entry`, `accessory_entry`, `seat_id`, `minion`, `description`, `summontype`, `summontimer`)
VALUES
    (40505, 40511, 0, 1, 'Steamwheedle Balloon - Throwing Station', 8, 0);

-- The action bar belongs to vehicle 752 (the throwing station), whose seat is
-- controllable.  Keeping duplicate spells on the non-controlling outer
-- balloon can expose an unusable second bar on clients that request pet data.
UPDATE `creature_template`
SET `spell1` = 0,
    `spell2` = 0,
    `spell6` = 0
WHERE `entry` = 40505;

UPDATE `creature_template`
SET `VehicleId` = 752,
    `spell1` = 75560,
    `spell2` = 73257,
    `spell6` = 75991,
    `ScriptName` = 'npc_balloon_throwing_station'
WHERE `entry` = 40511;

COMMIT;
