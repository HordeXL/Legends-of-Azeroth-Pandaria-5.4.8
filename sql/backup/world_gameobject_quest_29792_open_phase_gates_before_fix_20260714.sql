-- Backup of the two permanent alternate-phase gate states before
-- 2026_07_14_01_world_quest_29792_open_phase_gate_states.sql.

UPDATE `gameobject` SET `state` = 0
WHERE (`guid` = 540346 AND `id` = 211282 AND `phaseMask` = 2048)
   OR (`guid` = 539997 AND `id` = 211283 AND `phaseMask` = 4096);
