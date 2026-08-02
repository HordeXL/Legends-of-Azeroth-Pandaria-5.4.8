-- Exact rollback for
-- 2026_08_02_02_world_fix_dark_of_night_script_binding.sql.

UPDATE `spell_script_names`
SET `spell_id` = 123740
WHERE `spell_id` = 123742
  AND `ScriptName` = 'spell_dark_of_night_fixate';
