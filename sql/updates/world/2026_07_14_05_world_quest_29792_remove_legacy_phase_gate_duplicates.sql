-- Quest 29792 "Bidden to Greatness" already summons dedicated personal gates
-- 211294 and 211298 for its SmartAI scene.  These older alternate-phase world
-- spawns occupy the exact same coordinates, become visible during quest phase
-- changes and leave a second collision object behind the animated gate.
-- Preserve the phase-2 base gates (210965/210964); remove only the two proven
-- legacy duplicates by both GUID and entry.

DELETE FROM `gameobject`
WHERE (`guid` = 540346 AND `id` = 211282 AND `phaseMask` = 2048)
   OR (`guid` = 539997 AND `id` = 211283 AND `phaseMask` = 4096);
