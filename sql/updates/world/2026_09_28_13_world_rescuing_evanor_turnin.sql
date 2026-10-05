-- Rescuing Evanor (11681): recover players who arrived at Amber Ledge while
-- the former prison event left the hidden exploration objective incomplete.
UPDATE `creature_template`
SET `ScriptName` = 'npc_archmage_evanor_turnin'
WHERE `entry` = 25785;
