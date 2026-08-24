-- Remove 50 legacy master-pool shells after their empty child pools were audited.
-- The guards preserve any entry that has acquired any active reference.
START TRANSACTION;
DELETE pt FROM pool_template pt
LEFT JOIN pool_creature pc ON pc.pool_entry=pt.entry
LEFT JOIN pool_gameobject pg ON pg.pool_entry=pt.entry
LEFT JOIN pool_quest pq ON pq.pool_entry=pt.entry
LEFT JOIN game_event_pool gep ON gep.pool_entry=pt.entry
LEFT JOIN pool_pool pp_child ON pp_child.pool_id=pt.entry
LEFT JOIN pool_pool pp_mother ON pp_mother.mother_pool=pt.entry
WHERE pt.entry IN (5246,5247,5248,5336,5339,5340,5343,5344,5345,5350,5354,5356,5357,5358,5359,5360,5361,5365,5369,5370,5373,5375,5377,5378,5379,5390,5399,5402,5407,5409,5410,5441,5477,5480,5486,5487,5495,5496,5605,5606,5607,5608,5609,5611,5612,5613,5615,5616,5617,5618)
AND pc.guid IS NULL AND pg.guid IS NULL AND pq.entry IS NULL
AND gep.pool_entry IS NULL AND pp_child.pool_id IS NULL AND pp_mother.pool_id IS NULL;
COMMIT;

