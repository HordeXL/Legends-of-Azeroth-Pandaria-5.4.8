-- Restore the original client-side startOpen inversion for the two permanent
-- alternate-phase gates if the 2026-07-14 template correction is reverted.

UPDATE `gameobject_template`
SET `data0` = 1
WHERE `entry` IN (211282, 211283);
