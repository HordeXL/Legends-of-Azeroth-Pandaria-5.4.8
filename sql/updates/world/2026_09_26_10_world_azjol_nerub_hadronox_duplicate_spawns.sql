-- Hadronox and the initial crusher pack are created by EVENT_RESET_HADRONOX
-- after Krik'thir dies, including on loaded saves and encounter resets.
-- Disable their duplicate database spawns in normal and heroic Azjol-Nerub.
-- Retain the rows for rollback; the instance script owns the active encounter.
UPDATE `creature` SET `spawnMask`=0
WHERE `map`=601 AND `id` IN (28921,28922,29117,29118);
