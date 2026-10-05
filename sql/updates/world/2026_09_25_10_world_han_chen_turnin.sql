-- Han Stormstout (31078): the only turn-in Chen was at Sunset Brewgarden.
-- Preserve that shared quest giver; add a stationary Chen at the quest's
-- completion POI (817,3763). Nearby cave spawns establish floor Z=211.217.
-- Immunity prevents surrounding mantid from removing the turn-in NPC.
INSERT INTO `creature`
(`id`,`map`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,
 `orientation`,`spawntimesecs`,`MovementType`,`npcflag`,`unit_flags`)
SELECT 62779,870,1,1,817,3763,211.217,1.570796,120,0,2,768
WHERE NOT EXISTS
(SELECT 1 FROM `creature` WHERE `id`=62779 AND `map`=870
 AND `position_x` BETWEEN 812 AND 822 AND `position_y` BETWEEN 3758 AND 3768
 AND `position_z` BETWEEN 208 AND 215);
