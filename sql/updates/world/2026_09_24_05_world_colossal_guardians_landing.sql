-- Colossal Guardians: complete dismount/landing and retain a ground-level home.
-- Both accessories are summoned by their own Orsis vehicle. Target that summoner
-- directly instead of relying on a nearest-creature search within 3 yards.
-- Allow a short delay between removing the ride aura and launching the jump.
-- At the existing Thunderclap delay, finish at the authored ground destination
-- and save it as home: accessories otherwise inherit the underground base home.
-- Preserve jump visuals, dialogue, quest spells, faction and combat timing
-- apart from the extra 100 ms dismount allowance. Map 1 is Kalimdor.
-- Requires the preceding 2026_09_24_04 activation fix. Restart worldserver.
START TRANSACTION;
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (4604100,4604200) AND `source_type`=9;
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
('4604100','9','0','0','0','0','100','0','2000','2000','0','0','0','45','0','1','0','0','0','0','23','0','0','0','0','0','0','0','0','Colossus of the Sun - On Script - Set Data 0 1 - Own Summoner'),
('4604100','9','1','0','0','0','100','0','100','100','0','0','0','97','10','10','0','0','0','0','1','0','0','0','0','-9718.43','-14.1545','87.3271','0','Colossus of the Sun - On Script - Jump To Pos'),
('4604100','9','2','0','0','0','100','0','1300','1300','0','0','0','62','1','0','0','0','0','0','1','0','0','0','0','-9718.43','-14.1545','87.3271','4.08407','Colossal Guardian - After Jump - Finish At Ground Position'),
('4604100','9','3','0','0','0','100','0','0','0','0','0','0','101','0','0','0','0','0','0','1','0','0','0','0','0','0','0','0','Colossal Guardian - After Landing - Set Home Position'),
('4604100','9','4','0','0','0','100','0','0','0','0','0','0','11','85840','16','0','0','0','0','1','0','0','0','0','0','0','0','0','Colossus of the Sun - On Script - Cast Thunderclap'),
('4604100','9','5','0','0','0','100','0','0','0','0','0','0','1','0','0','0','0','0','0','1','0','0','0','0','0','0','0','0','Colossus of the Sun - On Script - Say Line 0'),
('4604100','9','6','0','0','0','100','0','3000','3000','0','0','0','2','14','0','0','0','0','0','1','0','0','0','0','0','0','0','0','Colossus of the Sun - On Script - Set Faction 14'),
('4604100','9','7','0','0','0','100','0','0','0','0','0','0','8','2','0','0','0','0','0','1','0','0','0','0','0','0','0','0','Colossus of the Sun - On Script - Set React Aggressive'),
('4604200','9','0','0','0','0','100','0','2000','2000','0','0','0','45','0','1','0','0','0','0','23','0','0','0','0','0','0','0','0','Colossus of the Moon - On Script - Set Data 0 1 - Own Summoner'),
('4604200','9','1','0','0','0','100','0','100','100','0','0','0','97','10','10','0','0','0','0','1','0','0','0','0','-9585.54','-110.891','95.8086','0','Colossus of the Moon - On Script - Jump To Pos'),
('4604200','9','2','0','0','0','100','0','1300','1300','0','0','0','62','1','0','0','0','0','0','1','0','0','0','0','-9585.54','-110.891','95.8086','2.42601','Colossal Guardian - After Jump - Finish At Ground Position'),
('4604200','9','3','0','0','0','100','0','0','0','0','0','0','101','0','0','0','0','0','0','1','0','0','0','0','0','0','0','0','Colossal Guardian - After Landing - Set Home Position'),
('4604200','9','4','0','0','0','100','0','0','0','0','0','0','11','85840','16','0','0','0','0','1','0','0','0','0','0','0','0','0','Colossus of the Moon - On Script - Cast Thunderclap'),
('4604200','9','5','0','0','0','100','0','0','0','0','0','0','1','0','0','0','0','0','0','1','0','0','0','0','0','0','0','0','Colossus of the Moon - On Script - Say Line 0'),
('4604200','9','6','0','0','0','100','0','3000','3000','0','0','0','2','14','0','0','0','0','0','1','0','0','0','0','0','0','0','0','Colossus of the Moon - On Script - Set Faction 14'),
('4604200','9','7','0','0','0','100','0','0','0','0','0','0','8','2','0','0','0','0','0','1','0','0','0','0','0','0','0','0','Colossus of the Moon - On Script - Set React Aggressive');
COMMIT;
