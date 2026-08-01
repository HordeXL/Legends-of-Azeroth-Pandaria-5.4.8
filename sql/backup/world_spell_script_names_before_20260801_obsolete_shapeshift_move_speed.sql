-- Exact rollback row for the obsolete Shapeshift Movement Speed script
-- association removed by 2026_08_01_08_world_remove_obsolete_shapeshift_move_speed_binding.sql.
--
-- Build 18414 marks spell 23218 with SPELL_ATTR0_OUTDOORS_ONLY. The core
-- enforces that attribute directly. Restoring this row would reattach a
-- DoCheckAreaTarget hook to a self aura that has no area-aura effect.

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(23218, 'spell_dru_shapeshift_move_speed');
