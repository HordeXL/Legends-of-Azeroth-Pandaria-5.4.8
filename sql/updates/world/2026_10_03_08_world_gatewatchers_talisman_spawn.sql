-- The Gatewatcher's Talisman (29811): provide a reliable quest pickup at the
-- entrance to Anub'arak's room in Azjol-Nerub, beside Reclaimer A'zak.

START TRANSACTION;

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId`=4 AND `SourceGroup`=444007
  AND `SourceEntry`=74616;

DELETE FROM `gameobject_loot_template`
WHERE `entry`=444007;

DELETE FROM `gameobject`
WHERE `guid`=4000146 OR `id`=444007;

DELETE FROM `gameobject_template`
WHERE `entry`=444007;

INSERT INTO `gameobject_template`
(`entry`,`type`,`displayId`,`name`,`IconName`,`castBarCaption`,`unk1`,`size`,
 `questItem1`,`data0`,`data1`,`data2`,`data3`,`data6`,`AIName`,`ScriptName`,
 `VerifiedBuild`) VALUES
(444007,10,335,'The Gatewatcher\'s Talisman','','Opening','',0.75,
 74616,0,29811,0,0,0,'','go_gatewatchers_talisman',18414);

INSERT INTO `gameobject`
(`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`phaseId`,`phaseGroup`,
 `position_x`,`position_y`,`position_z`,`orientation`,`rotation0`,`rotation1`,
 `rotation2`,`rotation3`,`spawntimesecs`,`animprogress`,`state`,`ScriptName`,
 `VerifiedBuild`) VALUES
(4000146,444007,601,4277,4405,6,1,0,0,
 559.0,335.0,241.5,3.14159,0,0,1,0,5,255,1,'',18414);

COMMIT;
