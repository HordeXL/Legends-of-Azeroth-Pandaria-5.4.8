-- Exact pre-change state before restoring the matching SkyFire 5.4.8 loot rows.
-- All listed creature/gameobject loot keys were absent from the active database.
-- Owner templates, item templates, personal loot and conditions are not changed.

START TRANSACTION;

DELETE FROM `creature_loot_template`
WHERE (`entry`, `item`, `lootmode`) IN
      ((60491, 89317, 1));

DELETE FROM `gameobject_loot_template`
WHERE (`entry`, `item`, `lootmode`) IN
      ((218197, 93962, 1),
       (218577, 46109, 1),
       (218577, 74857, 1),
       (218577, 86545, 1),
       (218577, 88496, 1),
       (218577, 94935, 1),
       (218577, 97981, 1),
       (220196, 81205, 1),
       (220196, 82011, 1),
       (220196, 82121, 1),
       (220196, 82126, 1),
       (220196, 82157, 1),
       (220196, 82208, 1),
       (220196, 82285, 1),
       (221776, 87282, 1),
       (221776, 87389, 1));

COMMIT;
