-- Guarded cleanup of the final inert legacy resource child pools, batch 13.
-- Physical gameobject rows are untouched.
START TRANSACTION;
DELETE pp FROM pool_pool pp LEFT JOIN pool_creature pc ON pc.pool_entry=pp.pool_id LEFT JOIN pool_gameobject pg ON pg.pool_entry=pp.pool_id LEFT JOIN pool_quest pq ON pq.pool_entry=pp.pool_id LEFT JOIN game_event_pool gep ON gep.pool_entry=pp.pool_id LEFT JOIN pool_pool child ON child.mother_pool=pp.pool_id WHERE pp.pool_id IN (2871,2872,2873,2874,2876,2877,2879,2880,2881) AND pc.guid IS NULL AND pg.guid IS NULL AND pq.entry IS NULL AND gep.pool_entry IS NULL AND child.pool_id IS NULL;
DELETE pt FROM pool_template pt LEFT JOIN pool_creature pc ON pc.pool_entry=pt.entry LEFT JOIN pool_gameobject pg ON pg.pool_entry=pt.entry LEFT JOIN pool_quest pq ON pq.pool_entry=pt.entry LEFT JOIN game_event_pool gep ON gep.pool_entry=pt.entry LEFT JOIN pool_pool pp_child ON pp_child.pool_id=pt.entry LEFT JOIN pool_pool pp_mother ON pp_mother.mother_pool=pt.entry WHERE pt.entry IN (2871,2872,2873,2874,2876,2877,2879,2880,2881) AND pc.guid IS NULL AND pg.guid IS NULL AND pq.entry IS NULL AND gep.pool_entry IS NULL AND pp_child.pool_id IS NULL AND pp_mother.pool_id IS NULL;
COMMIT;

