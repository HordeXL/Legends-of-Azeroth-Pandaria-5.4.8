-- Exact rollback for the Crossbow Dart script association moved by
-- 2026_08_01_18_world_rebind_crossbow_xin_dart_damage.sql.
--
-- The inherited database associated spell_crossbow_xin with 120124. Build
-- 18414 defines 120124 as a self-targeted 20% heal, while the script itself
-- validates SPELL_DART_DAMAGE (120142). Restoring this state will also restore
-- the corresponding startup target-hook mismatch.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 120142
  AND `ScriptName` = 'spell_crossbow_xin';

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(120124, 'spell_crossbow_xin');
