-- Remove two unusable child links from the old Tin/Silver vein master pools.
--
-- Neither child has a pool_template row or any pool_gameobject,
-- pool_creature, or pool_quest members in the active database or the three
-- preserved pre-recovery database copies. Both links exist in the old local
-- 2024 base, but are absent from SFDB 548 release 25.001 and both preserved
-- Downloads world dumps. The core has always skipped them, so this does not
-- remove a working spawn; it only removes two dangling references.

DELETE FROM `pool_pool`
WHERE (`pool_id` = 6576 AND `mother_pool` = 9234 AND `chance` = 0 AND `description` = '')
   OR (`pool_id` = 6590 AND `mother_pool` = 9238 AND `chance` = 0 AND `description` = '');
