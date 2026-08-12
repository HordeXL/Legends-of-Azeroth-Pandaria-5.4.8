-- Kylo Kelwin (69318) and Herwin Steampop (69321) are neutral legacy Arena
-- vendors in the Dalaran Underbelly and must be usable by both factions.
-- Their inherited Build-18414 templates incorrectly use hostile faction 14,
-- unlike the adjacent neutral PvP vendors, which use faction 35.
-- Change only the two exact hostile templates; do not alter their spawns,
-- inventories, flags, or any other creature data.
UPDATE `creature_template`
SET `faction` = 35
WHERE `entry` IN (69318, 69321)
  AND `faction` = 14;
