-- Exact rollback for
-- 2026_08_02_06_world_fix_primordius_mutation_binding.sql.

UPDATE `spell_script_names`
SET `spell_id` = 136203
WHERE `spell_id` = 136178
  AND `ScriptName` = 'spell_mutation_primordius';
