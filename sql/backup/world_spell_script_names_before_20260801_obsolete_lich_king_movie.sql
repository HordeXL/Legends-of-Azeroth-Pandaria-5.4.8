-- Exact rollback row for the obsolete pre-MoP Lich King movie script
-- association removed by 2026_08_01_05_world_remove_obsolete_lich_king_movie_binding.sql.
--
-- Build 18414 spell 73159 uses the native SPELL_EFFECT_PLAY_MOVIE effect with
-- MiscValue 16. Restoring this row would reattach the older script-effect
-- implementation and restore its startup hook mismatch.

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(73159, 'spell_the_lich_king_play_movie');
