-- Remove batch 02 of inert legacy resource child-pool shells.
-- All membership and event references are guarded; physical spawns are untouched.
START TRANSACTION;
DELETE pp FROM pool_pool pp
LEFT JOIN pool_creature pc ON pc.pool_entry=pp.pool_id
LEFT JOIN pool_gameobject pg ON pg.pool_entry=pp.pool_id
LEFT JOIN pool_quest pq ON pq.pool_entry=pp.pool_id
LEFT JOIN game_event_pool gep ON gep.pool_entry=pp.pool_id
LEFT JOIN pool_pool child ON child.mother_pool=pp.pool_id
WHERE pp.pool_id IN (1416,1417,1418,1419,1420,1421,1422,1423,1424,1425,1428,1430,1433,1439,1440,1448,1452,1453,1456,1459,1461,1476,1500,1503,1504,1505,1507,1508,1514,1516,1519,1521,1522,1524,1525,1527,1531,1535,1536,1543,1552,1554,1561,1568,1574,1579,1582,1600,1612,1615)
AND pc.guid IS NULL AND pg.guid IS NULL AND pq.entry IS NULL
AND gep.pool_entry IS NULL AND child.pool_id IS NULL;
DELETE pt FROM pool_template pt
LEFT JOIN pool_creature pc ON pc.pool_entry=pt.entry
LEFT JOIN pool_gameobject pg ON pg.pool_entry=pt.entry
LEFT JOIN pool_quest pq ON pq.pool_entry=pt.entry
LEFT JOIN game_event_pool gep ON gep.pool_entry=pt.entry
LEFT JOIN pool_pool pp_child ON pp_child.pool_id=pt.entry
LEFT JOIN pool_pool pp_mother ON pp_mother.mother_pool=pt.entry
WHERE pt.entry IN (1416,1417,1418,1419,1420,1421,1422,1423,1424,1425,1428,1430,1433,1439,1440,1448,1452,1453,1456,1459,1461,1476,1500,1503,1504,1505,1507,1508,1514,1516,1519,1521,1522,1524,1525,1527,1531,1535,1536,1543,1552,1554,1561,1568,1574,1579,1582,1600,1612,1615)
AND pc.guid IS NULL AND pg.guid IS NULL AND pq.entry IS NULL
AND gep.pool_entry IS NULL AND pp_child.pool_id IS NULL AND pp_mother.pool_id IS NULL;
COMMIT;

