-- Exact rollback rows for the obsolete Timeless Isle script associations
-- removed by 2026_08_01_06_world_remove_obsolete_timeless_isle_native_effect_bindings.sql.
--
-- Build 18414 implements both spells natively in SpellEffect.dbc. Restoring
-- these rows would reattach handlers that expect a nonexistent periodic-dummy
-- aura and restore their startup hook diagnostics.

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(147703, 'spell_timeless_isle_burning_fury'),
(147997, 'spell_timeless_isle_cauterize');
