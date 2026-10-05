-- The Poisoned Mind begins outside the Amber Womb, around Dread Wastes 28.7,42.2.
-- Existing 62151 spawns were both at Klaxxi'vess; preserve them and their quests.
-- Surface Z verified against installed map 870 terrain at the cave entrance.
INSERT INTO `creature`
(`id`,`map`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,
 `orientation`,`spawntimesecs`,`MovementType`,`npcflag`,`unit_flags`)
SELECT 62151,870,1,1,-89.346,4603.535,80.673,1.570796,120,0,3,768
WHERE NOT EXISTS
(SELECT 1 FROM `creature` WHERE `id`=62151 AND `map`=870
 AND `position_x` BETWEEN -94 AND -84 AND `position_y` BETWEEN 4598 AND 4609
 AND `position_z` BETWEEN 78 AND 84);
