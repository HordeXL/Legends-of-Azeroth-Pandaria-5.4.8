-- Rescuing Evanor (11681): clicking Evanor's Prison must finish the scripted
-- rescue objective before Evanor teleports the player back to Amber Ledge.
UPDATE `quest_template_addon`
SET `SpecialFlags` = `SpecialFlags` | 2
WHERE `ID` = 11681;

UPDATE `gameobject_template`
SET `ScriptName` = 'go_evanors_prison'
WHERE `entry` = 187884;
