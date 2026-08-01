-- Exact rollback for the Mark of Nature script rebind performed by
-- 2026_08_01_10_world_rebind_mark_of_nature_trigger_spell.sql.
--
-- Before the fix the script was incorrectly attached to marker spell 25040,
-- while the reconstructed server-side area trigger spell 25042 had no binding.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 25042
  AND `ScriptName` = 'spell_mark_of_nature';

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(25040, 'spell_mark_of_nature');
