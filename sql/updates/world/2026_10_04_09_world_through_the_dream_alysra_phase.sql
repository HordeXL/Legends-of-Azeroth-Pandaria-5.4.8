-- Alysra ends Through the Dream (25325) and starts Return to Nordrassil
-- (25578). Keep her visible in both the normal world and Emerald Dream so the
-- phase aura can be removed after turn-in without stranding the player.
UPDATE `creature`
SET `phaseMask` = 32769
WHERE `id` = 40178 AND `map` = 1;
