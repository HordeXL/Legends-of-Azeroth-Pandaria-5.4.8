-- Remove stale pool metadata for ICC weekly quests retired in patch 4.0.3a.
-- The 5.4.8 project base has no pool_quest members or quest giver/end links
-- for these quests.  Guards keep the data if an administrator has since
-- attached any active member or event reference to the pools.
START TRANSACTION;

DELETE pp FROM pool_pool pp
LEFT JOIN pool_creature pc ON pc.pool_entry=pp.pool_id
LEFT JOIN pool_gameobject pg ON pg.pool_entry=pp.pool_id
LEFT JOIN pool_quest pq ON pq.pool_entry=pp.pool_id
LEFT JOIN game_event_pool gep ON gep.pool_entry=pp.pool_id
LEFT JOIN pool_pool nested ON nested.mother_pool=pp.pool_id
WHERE pp.mother_pool=517
  AND pp.pool_id IN (518,519,520,521,522)
  AND pc.guid IS NULL AND pg.guid IS NULL AND pq.entry IS NULL
  AND gep.pool_entry IS NULL AND nested.pool_id IS NULL;

DELETE pt FROM pool_template pt
LEFT JOIN pool_creature pc ON pc.pool_entry=pt.entry
LEFT JOIN pool_gameobject pg ON pg.pool_entry=pt.entry
LEFT JOIN pool_quest pq ON pq.pool_entry=pt.entry
LEFT JOIN game_event_pool gep ON gep.pool_entry=pt.entry
LEFT JOIN pool_pool pp_child ON pp_child.pool_id=pt.entry
LEFT JOIN pool_pool pp_mother ON pp_mother.mother_pool=pt.entry
WHERE pt.entry IN (517,518,519,520,521,522)
  AND pc.guid IS NULL AND pg.guid IS NULL AND pq.entry IS NULL
  AND gep.pool_entry IS NULL
  AND pp_child.pool_id IS NULL AND pp_mother.pool_id IS NULL;

COMMIT;
