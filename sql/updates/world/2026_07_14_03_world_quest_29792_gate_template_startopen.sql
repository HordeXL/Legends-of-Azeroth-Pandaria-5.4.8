-- Quest 29792 "Bidden to Greatness": permanent alternate-phase copies become
-- visible briefly alongside the correctly activated personal gates.  Their
-- startOpen=1 reverses client animation interpretation, leaving a closed
-- visual/collision copy until the next phase update.  Match the working
-- personal gate templates (211294/211298), which use startOpen=0.

UPDATE `gameobject_template`
SET `data0` = 0
WHERE `entry` IN (211282, 211283)
  AND `type` = 0
  AND `data0` = 1;
