-- Startup DBErrors cleanup for 5.4.8 world database.
-- Non-destructive fixes only: keep existing data, fill/correct missing links.

-- SmartAI rows exist for these creature templates, but AIName was empty.
-- Templates with an existing C++ ScriptName are intentionally not changed here.
UPDATE `creature_template` SET `AIName`='SmartAI' WHERE `entry` IN
(35589, 35604, 37063, 64360, 64362, 64363, 64364, 66654)
AND IFNULL(`ScriptName`, '')=''
AND IFNULL(`AIName`, '')<>'SmartAI';
