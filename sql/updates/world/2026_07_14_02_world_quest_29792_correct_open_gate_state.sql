-- Correction for 2026_07_14_01: GOState values are
-- GO_STATE_ACTIVE = 0 (open) and GO_STATE_READY = 1 (closed).
-- Keep the permanent post-event phase copies open so they do not overlap
-- and block the personal SmartAI gates after quest credit changes phasing.

UPDATE `gameobject`
SET `state` = 0
WHERE `guid` = 540346
  AND `id` = 211282
  AND `phaseMask` = 2048
  AND `state` = 1;

UPDATE `gameobject`
SET `state` = 0
WHERE `guid` = 539997
  AND `id` = 211283
  AND `phaseMask` = 4096
  AND `state` = 1;
