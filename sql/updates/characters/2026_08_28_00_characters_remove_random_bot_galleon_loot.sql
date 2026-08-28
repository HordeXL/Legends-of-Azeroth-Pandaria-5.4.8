-- Remove the exact personal-loot batch awarded to headless random bots during
-- the 2026-08-28 Boss Bot Caller Galleon test. Item GUIDs 39811..39829 were
-- allocated consecutively by that single kill: 14 equipment rewards and five
-- Marauder's Gleaming Sacks of Gold. Existing bot equipment and older bag
-- contents are intentionally untouched.

START TRANSACTION;

DELETE FROM `character_inventory`
WHERE (`guid`, `bag`, `slot`, `item`) IN
(
    (60, 0, 30, 39811), (67, 0, 30, 39812), (74, 0, 30, 39813),
    (77, 0, 30, 39814), (81, 0, 31, 39815), (200, 0, 32, 39816),
    (210, 0, 31, 39817), (229, 0, 30, 39818), (266, 0, 31, 39819),
    (295, 0, 31, 39820), (338, 0, 30, 39821), (427, 0, 31, 39822),
    (441, 0, 30, 39823), (451, 0, 30, 39824), (465, 0, 30, 39825),
    (479, 0, 30, 39826), (495, 0, 30, 39827), (1047, 0, 31, 39828),
    (1599, 0, 30, 39829)
);

DELETE FROM `item_instance`
WHERE (`guid`, `itemEntry`, `owner_guid`) IN
(
    (39811, 90840, 60), (39812, 90409, 67), (39813, 90442, 74),
    (39814, 90412, 77), (39815, 90450, 81), (39816, 90435, 200),
    (39817, 90840, 210), (39818, 90840, 229), (39819, 90439, 266),
    (39820, 90840, 295), (39821, 90451, 338), (39822, 90448, 427),
    (39823, 90439, 441), (39824, 90422, 451), (39825, 90411, 465),
    (39826, 90447, 479), (39827, 90840, 495), (39828, 90409, 1047),
    (39829, 90419, 1599)
);

COMMIT;
