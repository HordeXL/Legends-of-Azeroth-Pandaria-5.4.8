-- Exact rollback for
-- 2026_08_02_04_world_remove_invalid_grab_air_balloon_binding.sql.

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(128815, 'spell_grab_air_balloon');
