-- Quest 11685 "The Heart of the Elements": Frozen Elementals at the intended
-- coast objective (around 83,47) were restricted to phase mask 1.  Players in
-- another Borean Tundra phase could only see the three unrelated spawns across
-- the zone boundary to the east.  These are ordinary quest mobs and must remain
-- available throughout the zone's quest progression.
UPDATE `creature`
SET `phaseMask` = 65535
WHERE `id` = 25715
  AND `map` = 571;
