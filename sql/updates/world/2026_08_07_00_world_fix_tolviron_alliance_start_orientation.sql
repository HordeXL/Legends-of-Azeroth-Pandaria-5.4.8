-- Tol'viron Arena (719): WorldSafeLoc 4136 places Alliance east of its
-- preparation-room exit, while the exit door is west at X=-10655.  The
-- inherited orientation 0 faces east, directly away from that door.  Runtime
-- testing therefore spawned the Alliance player facing the rear wall even
-- though the real door opened correctly.  Pi faces west toward the exit.
--
-- Change only the one proven-bad orientation and guard every relevant part of
-- the inherited row.  Horde orientation 0 is already correct for its room.

UPDATE `battleground_template`
SET `AllianceStartO` = 3.14159
WHERE `id` = 719
  AND `AllianceStartLoc` = 4136
  AND `AllianceStartO` = 0
  AND `HordeStartLoc` = 4137
  AND `HordeStartO` = 0
  AND `Comment` = 'Tol\'viron Arena';
