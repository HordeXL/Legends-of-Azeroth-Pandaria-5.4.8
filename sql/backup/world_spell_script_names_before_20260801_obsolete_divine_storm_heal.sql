-- Exact rollback row for the obsolete pre-MoP Divine Storm party-heal script
-- association removed by 2026_08_01_04_world_remove_obsolete_divine_storm_heal_binding.sql.
--
-- Build 18414 contains spell 53385, but not the helper spells 54171 and 54172
-- required by this legacy implementation. The valid spell_pal_divine_purpose
-- and spell_pal_glyph_of_divine_storm associations are intentionally omitted
-- from this backup because the migration does not change them.

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(53385, 'spell_pal_divine_storm');
