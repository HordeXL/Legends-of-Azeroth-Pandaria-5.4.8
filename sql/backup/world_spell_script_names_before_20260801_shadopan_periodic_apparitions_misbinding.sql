-- Exact rollback for 2026_08_01_15_world_remove_shadopan_periodic_apparitions_misbinding.sql.
-- Restores only the inherited association present before the correction.

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(111698, 'spell_shadopan_apparitions');
