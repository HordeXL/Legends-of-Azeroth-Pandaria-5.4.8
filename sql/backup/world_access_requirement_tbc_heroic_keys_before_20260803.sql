-- Exact rollback for 2026_08_03_00_world_remove_obsolete_tbc_heroic_key_requirements.sql.
-- These are the values present in the active world database before the fix.

UPDATE `access_requirement`
SET `item` = 30637, `item2` = 30622
WHERE `mapId` IN (540, 542, 543)
  AND `difficulty` = 'DUNGEON_HEROIC';

UPDATE `access_requirement`
SET `item` = 30623, `item2` = 0
WHERE `mapId` IN (545, 546, 547)
  AND `difficulty` = 'DUNGEON_HEROIC';

UPDATE `access_requirement`
SET `item` = 30634, `item2` = 0
WHERE `mapId` IN (552, 553, 554)
  AND `difficulty` = 'DUNGEON_HEROIC';

UPDATE `access_requirement`
SET `item` = 30633, `item2` = 0
WHERE `mapId` IN (555, 556, 557, 558)
  AND `difficulty` = 'DUNGEON_HEROIC';

UPDATE `access_requirement`
SET `item` = 30635, `item2` = 0
WHERE `mapId` = 560
  AND `difficulty` = 'DUNGEON_HEROIC';
