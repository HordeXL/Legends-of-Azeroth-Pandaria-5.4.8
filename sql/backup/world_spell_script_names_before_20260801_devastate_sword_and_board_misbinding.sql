-- Exact rollback row for the Devastate/Sword and Board misbinding removed by
-- 2026_08_01_09_world_remove_devastate_sword_and_board_misbinding.sql.
--
-- Build 18414 spell 20243 is Devastate and has no aura. The same script stays
-- correctly attached to Sword and Board passive spell 46953.

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(20243, 'spell_warr_sword_and_board');
