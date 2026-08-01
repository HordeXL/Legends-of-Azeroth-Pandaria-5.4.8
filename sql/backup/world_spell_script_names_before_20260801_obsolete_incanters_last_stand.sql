-- Exact active rows backed up before removing obsolete pre-MoP script bindings.
-- Run this file only to restore the bindings removed by
-- 2026_08_01_02_world_remove_obsolete_incanters_last_stand_bindings.sql.
INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(11426,  'spell_mage_incanters_absorbtion_absorb'),
(116267, 'spell_mage_incanters_absorbtion_absorb'),
(1463,   'spell_mage_incanters_absorbtion_manashield'),
(144318, 'spell_mage_incanters_absorbtion_manashield'),
(12975,  'spell_warr_last_stand');
