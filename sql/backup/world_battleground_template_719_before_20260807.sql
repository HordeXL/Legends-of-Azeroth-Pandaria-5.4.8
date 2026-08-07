-- Exact rollback for the Tol'viron Arena Alliance start-orientation change.
-- Captured from active Wamp MySQL 5.7.44 world.battleground_template on
-- 2026-08-07 before applying the matching world update.

UPDATE `battleground_template`
SET `AllianceStartO` = 0
WHERE `id` = 719
  AND `AllianceStartLoc` = 4136
  AND ABS(`AllianceStartO` - 3.14159) < 0.00001
  AND `HordeStartLoc` = 4137
  AND `HordeStartO` = 0
  AND `Comment` = 'Tol\'viron Arena';
