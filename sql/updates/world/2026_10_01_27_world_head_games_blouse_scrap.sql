-- Head Games (13129)
-- Handle Kurzel's Blouse Scrap explicitly because its use spell does not
-- create the required Ichor-Stained Cloth on this core.

DELETE FROM `item_script_names`
WHERE `Id` = 43214;

INSERT INTO `item_script_names` (`Id`, `ScriptName`)
VALUES (43214, 'item_kurzels_blouse_scrap');
