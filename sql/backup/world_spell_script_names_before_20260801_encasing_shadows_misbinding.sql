-- Exact rollback for 2026_08_01_14_world_remove_encasing_shadows_misbinding.sql.
-- Restores only the inherited association present before the correction.

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(92023, 'spell_lord_victor_nefarius_encasing_shadows');
