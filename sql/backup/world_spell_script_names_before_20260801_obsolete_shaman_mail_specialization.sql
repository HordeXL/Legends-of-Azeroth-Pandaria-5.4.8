-- Exact rollback row for the obsolete Shaman Mail Specialization script
-- association removed by 2026_08_01_07_world_remove_obsolete_shaman_mail_specialization_binding.sql.
--
-- Build 18414 teaches the three specialization-specific bonus spells through
-- SpecializationSpells.dbc. Restoring this row would reattach an AuraScript to
-- spell 86529, whose sole effect is SPELL_EFFECT_DUMMY rather than an aura.

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(86529, 'spell_sha_mail_specialization');
