-- SkyFire 5.4.8 source:
-- C:/wamp64/www/SFDB_full_548_25.001_2026_007_19_Release/
-- SFDB_full_548_25.001_2026_007_19_Release.sql
--
-- The matching-version source keeps all of these heroic access rows but has
-- item/item2 set to zero. The active rows still referenced removed Burning
-- Crusade keys, so WorldServer discarded the requirements at every startup.
-- Keep every access row and clear only the proven obsolete key references.

UPDATE `access_requirement`
SET `item` = 0, `item2` = 0
WHERE `mapId` IN (540, 542, 543)
  AND `difficulty` = 'DUNGEON_HEROIC'
  AND `item` = 30637
  AND `item2` = 30622;

UPDATE `access_requirement`
SET `item` = 0, `item2` = 0
WHERE `mapId` IN (545, 546, 547)
  AND `difficulty` = 'DUNGEON_HEROIC'
  AND `item` = 30623
  AND `item2` = 0;

UPDATE `access_requirement`
SET `item` = 0, `item2` = 0
WHERE `mapId` IN (552, 553, 554)
  AND `difficulty` = 'DUNGEON_HEROIC'
  AND `item` = 30634
  AND `item2` = 0;

UPDATE `access_requirement`
SET `item` = 0, `item2` = 0
WHERE `mapId` IN (555, 556, 557, 558)
  AND `difficulty` = 'DUNGEON_HEROIC'
  AND `item` = 30633
  AND `item2` = 0;

UPDATE `access_requirement`
SET `item` = 0, `item2` = 0
WHERE `mapId` = 560
  AND `difficulty` = 'DUNGEON_HEROIC'
  AND `item` = 30635
  AND `item2` = 0;
