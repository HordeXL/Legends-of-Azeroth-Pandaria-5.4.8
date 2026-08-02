-- Exact rollback for
-- 2026_08_02_05_world_remove_invalid_marked_for_death_binding.sql.

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(140149, 'spell_rog_marked_for_death');
