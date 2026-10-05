-- The Root of the Problem (31026): Coldbite Spawn hatch from Crocolisk Eggs.
-- Egg traps 212099/212100/212104/212105 already cast summon spell 121191 (62228).
-- Disable the 30 duplicate permanent spawns in Coldbite Burrow, preserving rows.
-- Summoned creatures, the Matriarch, and her separate hatchling spells are unchanged.
UPDATE `creature` SET `spawnMask`=0
WHERE `id`=62228 AND `map`=870 AND `spawnMask`=1
  AND `position_x` BETWEEN -700 AND -630
  AND `position_y` BETWEEN 3020 AND 3080
  AND `position_z` BETWEEN 100 AND 120;
