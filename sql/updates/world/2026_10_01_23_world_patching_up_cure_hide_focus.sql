-- Patching Up (11894): remove the invalid attempted override of client spell
-- 46387.  spell_dbc only accepts server-only spell IDs that do not already
-- exist in Spell.dbc; overriding this ID prevents the worldserver from booting.
DELETE FROM `spell_dbc`
WHERE `Id`=46387;
