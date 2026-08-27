-- Quest 29792 "Bidden to Greatness" already summons dedicated personal gates
-- 211294 and 211298 and opens those copies through the working SmartAI scene.
-- The phase-2 base spawns occupy the same coordinates and Build 18414 can keep
-- their old model and collision after the player leaves phase 2, despite an
-- explicit visibility removal packet. Remove only those two confirmed duplicate
-- spawns so the animated personal gate is the sole physical gate at each scene.

DELETE FROM `object_visibility_state`
WHERE `type` = 'GameObject'
  AND `entryorguid` IN (-540359, -540026);

DELETE FROM `gameobject`
WHERE (`guid` = 540359 AND `id` = 210965 AND `map` = 860)
   OR (`guid` = 540026 AND `id` = 210964 AND `map` = 860);
