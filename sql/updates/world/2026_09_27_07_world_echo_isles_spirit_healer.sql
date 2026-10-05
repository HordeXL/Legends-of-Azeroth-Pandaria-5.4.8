-- Echo Isles graveyard 1700 has no Spirit Healer spawn.
-- Coordinates are from the server's WorldSafeLocs.dbc entry 1700.
INSERT INTO `creature`
(`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,
 `position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`curhealth`,`MovementType`)
SELECT 9001700,6491,1,6453,6453,1,4294967295,
       -1044.98,-5417.07,11.9356,0,30,0,0
WHERE NOT EXISTS (SELECT 1 FROM `creature` WHERE `guid`=9001700)
  AND NOT EXISTS (SELECT 1 FROM `creature` WHERE `map`=1
      AND `id` IN (6491,29259,39660,65183,72676)
      AND POW(`position_x`+1044.98,2)+POW(`position_y`+5417.07,2)<2500);
