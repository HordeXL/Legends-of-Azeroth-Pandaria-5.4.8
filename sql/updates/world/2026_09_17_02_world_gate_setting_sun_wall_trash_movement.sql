-- Gate of the Setting Sun: these trash spawns stand on narrow elevated walls.
-- A 10-yard random movement radius lets them walk off the edge before combat
-- and then evade back to their elevated home position.
UPDATE `creature`
SET `wander_distance` = 0,
    `MovementType` = 0
WHERE `map` = 962
  AND `guid` IN (541801, 541802, 542282, 542283, 542284, 542285)
  AND `id` IN (58108, 59801)
  AND `wander_distance` = 10
  AND `MovementType` = 1;
