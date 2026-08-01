-- Exact rollback row for the impossible Devastating Arc AuraScript binding
-- removed by 2026_08_01_17_world_remove_devastating_arc_non_aura_misbinding.sql.
--
-- Build 18414 defines spell 117006 as a dummy cone effect followed by a
-- native trigger of 116835. Restoring this row would reattach an AuraScript
-- to a spell with no aura effect and restore its startup hook diagnostic.

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(117006, 'spell_devastating_arc');
