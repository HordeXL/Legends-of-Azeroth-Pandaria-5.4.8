-- Exact rollback for an accidentally added item 102249 on playerbot Patrie.
-- Captured from the active `characters` database before the 2026-08-10 removal.
-- Run only while WorldServer is stopped. The INSERT statements intentionally
-- fail instead of overwriting data if item GUID 39393 or backpack slot 25 is
-- already occupied.

START TRANSACTION;

INSERT INTO `item_instance`
(`guid`,`itemEntry`,`owner_guid`,`creatorGuid`,`giftCreatorGuid`,`count`,`duration`,`charges`,`flags`,`enchantments`,`randomPropertyId`,`reforgeID`,`transmogrifyId`,`upgradeID`,`durability`,`playedTime`,`text`,`pet_species`,`pet_breed`,`pet_quality`,`pet_level`)
VALUES
(39393,102249,603,0,0,1,0,'0 0 0 0 0 ',1,'0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ',0,0,0,491,0,21559,'',0,0,0,0);

INSERT INTO `character_inventory` (`guid`,`bag`,`slot`,`item`)
VALUES (603,0,25,39393);

COMMIT;
