-- Exact rollback for
-- 2026_08_02_03_world_fix_explosive_ring_visual_binding.sql.

UPDATE `spell_script_names`
SET `spell_id` = 144194
WHERE `spell_id` = 144195
  AND `ScriptName` = 'spell_paragon_explosive_ring_visual';
