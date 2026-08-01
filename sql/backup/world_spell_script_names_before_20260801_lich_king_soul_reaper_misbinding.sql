-- Exact rollback row for the Lich King Soul Reaper/DK Soul Reaper misbinding
-- removed by 2026_08_01_11_world_remove_lich_king_soul_reaper_dk_misbinding.sql.
--
-- Build 18414 spell 69409 is the Icecrown Citadel encounter spell and remains
-- correctly attached to spell_the_lich_king_soul_reaper.

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(69409, 'spell_dk_soul_reaper');
