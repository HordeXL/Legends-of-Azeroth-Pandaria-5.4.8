-- Exact rollback for
-- 2026_08_01_12_world_rebind_omega_stance_spider_effect.sql.
--
-- Restores the single pre-change association captured from the active world
-- database. This rollback intentionally restores the old mismatched script.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 77127
  AND `ScriptName` IN
      ('spell_omega_stance_spider', 'spell_omega_stance_spider_effect');

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(77127, 'spell_omega_stance_spider');
