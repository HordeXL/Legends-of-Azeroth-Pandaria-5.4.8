-- Targeted pre-change backup. Both source GUIDs were absent in the active DB.
-- The event links themselves were restored by 2026_07_15_01.
SELECT * FROM `creature` WHERE `guid` IN (77232,136675);
