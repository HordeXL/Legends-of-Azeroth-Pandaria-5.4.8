-- Remove the final three inert resource child-pool shells.
-- Reference imports also contain no physical members for these pools.
START TRANSACTION;
DELETE pp FROM pool_pool pp LEFT JOIN pool_creature pc ON pc.pool_entry=pp.pool_id LEFT JOIN pool_gameobject pg ON pg.pool_entry=pp.pool_id LEFT JOIN pool_quest pq ON pq.pool_entry=pp.pool_id LEFT JOIN game_event_pool gep ON gep.pool_entry=pp.pool_id LEFT JOIN pool_pool child ON child.mother_pool=pp.pool_id WHERE pp.pool_id IN (7154,7713,8808) AND pc.guid IS NULL AND pg.guid IS NULL AND pq.entry IS NULL AND gep.pool_entry IS NULL AND child.pool_id IS NULL;
DELETE pt FROM pool_template pt LEFT JOIN pool_creature pc ON pc.pool_entry=pt.entry LEFT JOIN pool_gameobject pg ON pg.pool_entry=pt.entry LEFT JOIN pool_quest pq ON pq.pool_entry=pt.entry LEFT JOIN game_event_pool gep ON gep.pool_entry=pt.entry LEFT JOIN pool_pool pp_child ON pp_child.pool_id=pt.entry LEFT JOIN pool_pool pp_mother ON pp_mother.mother_pool=pt.entry WHERE pt.entry IN (7154,7713,8808) AND pc.guid IS NULL AND pg.guid IS NULL AND pq.entry IS NULL AND gep.pool_entry IS NULL AND pp_child.pool_id IS NULL AND pp_mother.pool_id IS NULL;
COMMIT;

