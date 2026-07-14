-- Quest 29792 "Bidden to Greatness": the permanent alternate-phase copies
-- represent the already-open Mandori and Pei-Wu gates.  Both were stored in
-- closed state 0 and could overlap the personal event gate collision.
-- Direct runtime testing proved that activating GUID 540346 (state 0 -> 1)
-- opens the blocking Mandori leaves.

UPDATE `gameobject`
SET `state` = 1
WHERE `guid` = 540346
  AND `id` = 211282
  AND `phaseMask` = 2048
  AND `state` = 0;

UPDATE `gameobject`
SET `state` = 1
WHERE `guid` = 539997
  AND `id` = 211283
  AND `phaseMask` = 4096
  AND `state` = 0;
