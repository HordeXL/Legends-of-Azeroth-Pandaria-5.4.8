-- Remove obsolete pool 210 without deleting either creature spawn.
--
-- Pool 210 contains the explicitly-chanced rare Swiftmane (entry 5831) in
-- Northern Barrens, map 1. The zero-chance fallback assigned to the same pool
-- is Skullsplitter Berserker (entry 783) in Northern Stranglethorn, map 0.
-- A pool may not combine creature spawns from different maps, so the core
-- rejects that form on startup. Removing only the unrelated fallback leaves
-- one 12% explicit-chance row with no zero-chance fallback, which is also an
-- invalid pool and is rejected by the core.
--
-- Surrounding pools use the normal pattern of a rare and a fallback creature
-- from the same local area. The latest local SFDB 548 release and the older
-- TDB 4.3.4 dump contain no pool_creature members for pool 210, while public
-- game data confirms Swiftmane itself belongs in Northern Barrens. There is no
-- sourced replacement fallback to add. Therefore the unusable pool wrapper is
-- removed, while both underlying creature spawn rows (including Swiftmane)
-- remain intact.

DELETE FROM `pool_creature`
WHERE `pool_entry` = 210
  AND `guid` IN (34973, 53202);

DELETE FROM `pool_template`
WHERE `entry` = 210
  AND `max_limit` = 1
  AND `description` = '';
