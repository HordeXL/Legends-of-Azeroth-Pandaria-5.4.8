-- Remove only the obsolete pre-MoP Divine Storm party-heal script binding.
--
-- The implementation requires helper spell 54171 (and historically 54172),
-- neither of which exists in the active Build-18414 Spell.dbc. MoP Divine
-- Storm spell 53385 and its valid spell_pal_divine_purpose and
-- spell_pal_glyph_of_divine_storm bindings remain untouched.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 53385
  AND `ScriptName` = 'spell_pal_divine_storm';
