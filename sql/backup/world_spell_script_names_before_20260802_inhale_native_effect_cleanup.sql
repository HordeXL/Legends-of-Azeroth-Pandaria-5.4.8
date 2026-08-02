-- Exact rollback for the inherited spell_inhale association removed by
-- 2026_08_02_01_world_remove_invalid_inhale_binding.sql.
--
-- Restoring this row reattaches the Zor'lok Inhale loader to Ta'yak's
-- Tempest Slash damage spell 122853 and restores the startup hook mismatch.

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(122853, 'spell_inhale');
