-- Strongarm Airstrip switches from Alliance to Horde after The Darkness
-- Within is complete or rewarded. Each player sees their own quest state.
START TRANSACTION;

DELETE FROM `phase_definitions` WHERE `zoneId`=5785 AND `entry` IN (7,8);
INSERT INTO `phase_definitions`
(`zoneId`,`entry`,`phasemask`,`phaseId`,`terrainswapmap`,`worldMapArea`,`flags`,`comment`) VALUES
(5785,7,268435456,0,0,0,0,'Strongarm Airstrip - before The Darkness Within completion'),
(5785,8,134217728,0,0,0,0,'Strongarm Airstrip - Horde takeover after The Darkness Within');
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=25 AND `SourceGroup`=5785 AND `SourceEntry` IN (7,8);
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,
`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,
`ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`) VALUES
(25,5785,7,0,0,8,0,31779,0,0,1,0,0,'','Alliance base - quest not rewarded'),
(25,5785,7,0,0,28,0,31779,0,0,1,0,0,'','Alliance base - quest not complete'),
(25,5785,8,0,0,8,0,31779,0,0,0,0,0,'','Horde base - quest rewarded'),
(25,5785,8,0,1,28,0,31779,0,0,0,0,0,'','Horde base - quest complete');

UPDATE `creature` SET `phaseMask`=268435456
WHERE `map`=870 AND `areaId`=5867
AND `id` IN (65840,65841,65842,65843,65880,65881,65882,65883,
             65905,65915,66000,66052,66897);

UPDATE `gameobject` SET `phaseMask`=268435456
WHERE `map`=870 AND `guid` IN
(545069,545070,545071,545072,545073,545074,545075,545076,545814)
AND `id` IN (215031,215032,215033,215034,215035,215036,215037,215038,215845);
UPDATE `gameobject` SET `phaseMask`=134217728
WHERE `map`=870 AND `guid` IN (501526,501529,501560,501578,501579)
AND `id` IN (215843,215849,215850);

-- Four Alliance banner positions had no Horde counterpart at all.
INSERT INTO `gameobject`
(`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,
`position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,
`rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`VerifiedBuild`)
SELECT a.`guid`+1000000,215850,a.`map`,a.`zoneId`,a.`areaId`,a.`spawnMask`,134217728,0,0,
a.`position_x`,a.`position_y`,a.`position_z`,a.`orientation`,a.`rotation0`,a.`rotation1`,
a.`rotation2`,a.`rotation3`,a.`spawntimesecs`,a.`animprogress`,a.`state`,a.`VerifiedBuild`
FROM `gameobject` a
WHERE a.`map`=870 AND a.`guid` IN (545069,545073,545074,545075)
AND NOT EXISTS (SELECT 1 FROM `gameobject` existing WHERE existing.`guid`=a.`guid`+1000000);

-- Shared quest NPCs must remain available even while another player's
-- pre-takeover Alliance enemies are still loaded in the same world grid.
UPDATE `creature` c JOIN `creature_template` t ON t.`entry`=c.`id`
SET c.`unit_flags`=(CASE WHEN c.`unit_flags`=0 THEN t.`unit_flags` ELSE c.`unit_flags` END) | 512
WHERE c.`map`=870 AND c.`guid` IN
(501641,501673,501674,501676,501691,505546,505553,501662,505545,505544,505547);

COMMIT;
