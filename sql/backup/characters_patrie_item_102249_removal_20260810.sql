-- Exact removal that was manually applied to the active `characters` database
-- while WorldServer was stopped on 2026-08-10.
-- Its reverse data is preserved in:
-- characters_patrie_item_102249_before_20260810.sql

START TRANSACTION;

DELETE FROM `character_inventory`
WHERE `guid` = 603 AND `bag` = 0 AND `slot` = 25 AND `item` = 39393;

DELETE FROM `item_instance`
WHERE `guid` = 39393 AND `itemEntry` = 102249 AND `owner_guid` = 603;

COMMIT;
