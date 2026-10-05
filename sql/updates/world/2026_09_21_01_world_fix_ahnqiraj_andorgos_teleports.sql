-- Wire Andorgos' AQ40 gossip options to the teleport script.
UPDATE `creature_template`
SET `ScriptName` = 'npc_andorgos'
WHERE `entry` = 15502;

UPDATE `gossip_menu_option`
SET `ActionMenuID` = 29182
WHERE `MenuID` = 6644 AND `OptionID` = 0;

UPDATE `gossip_menu_option`
SET `ActionMenuID` = 29188
WHERE `MenuID` = 6644 AND `OptionID` = 1;
