-- Remove an incomplete and unreachable Defias Prisoner timed action list.
--
-- The list has no SMART_ACTION_CALL_TIMED_ACTIONLIST caller anywhere in the
-- active database and its final action references missing waypoint path 1706.
-- Therefore none of its eleven actions can execute. It is absent from the
-- pre-restore world database and from the local TDB 4.3.4 / SFDB 5.4.8 source
-- snapshots; only the later world.sql backups contain this incomplete copy.
-- Creature template 1706 and both of its real spawns are deliberately kept.

DELETE FROM `smart_scripts`
WHERE `entryorguid` = 170600
  AND `source_type` = 9;
