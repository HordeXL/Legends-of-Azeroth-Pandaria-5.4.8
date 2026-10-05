-- Zen'Kiki, the Druid (26953): all four listed plagued wildlife types must
-- cast the Build-18414 quest-credit spell when they die. Hulking Plaguebear
-- (44482) already has this event; restore it for the other three creatures.
UPDATE `creature_template`
SET `AIName` = 'SmartAI'
WHERE `entry` IN (1817, 1822, 1824);

DELETE FROM `smart_scripts`
WHERE `source_type` = 0
  AND ((`entryorguid` = 1817 AND `id` = 1)
    OR (`entryorguid` IN (1822, 1824) AND `id` = 0));

INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`event_type`,`event_chance`,
 `action_type`,`action_param1`,`action_param2`,`target_type`,`comment`) VALUES
(1817,0,1,6,100,11,83484,2,1,'Diseased Wolf - On Death - Cast The Worst Druid wildlife credit'),
(1822,0,0,6,100,11,83484,2,1,'Venom Mist Lurker - On Death - Cast The Worst Druid wildlife credit'),
(1824,0,0,6,100,11,83484,2,1,'Plague Lurker - On Death - Cast The Worst Druid wildlife credit');
