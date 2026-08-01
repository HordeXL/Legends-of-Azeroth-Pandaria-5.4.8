-- Exact active rows backed up before removing incompatible spell_dart bindings.
-- Run this file only to restore the bindings removed by
-- 2026_08_01_03_world_remove_dart_misbindings.sql.
INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(119311, 'spell_dart'),
(119338, 'spell_dart'),
(120142, 'spell_dart');
