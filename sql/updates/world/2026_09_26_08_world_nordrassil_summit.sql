-- The Nordrassil Summit (29326): Thrall starts the quest and Aggra ends it.
-- The companion script gives ceremony credit when the player selects "I am ready."
DELETE FROM `creature_queststarter` WHERE `id` = 54312 AND `quest` = 29326;
INSERT IGNORE INTO `creature_queststarter` (`id`, `quest`) VALUES (54313, 29326);

DELETE FROM `creature_questender` WHERE `id` = 54313 AND `quest` = 29326;
INSERT IGNORE INTO `creature_questender` (`id`, `quest`) VALUES (54312, 29326);

UPDATE `creature_template`
SET `ScriptName` = 'npc_nordrassil_summit_thrall'
WHERE `entry` = 54313;
