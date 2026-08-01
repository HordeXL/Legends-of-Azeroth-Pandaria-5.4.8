-- Exact rollback row for the Tail Lash/Lightning Discharge misbinding removed
-- by 2026_08_01_13_world_remove_tail_lash_lightning_discharge_misbinding.sql.
--
-- Build 18414 spell 77827 is Tail Lash. Restoring this row also restores the
-- old target-filter mismatch and is intended only as an exact rollback.

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(77827, 'spell_onyxia_lightning_discharge');
