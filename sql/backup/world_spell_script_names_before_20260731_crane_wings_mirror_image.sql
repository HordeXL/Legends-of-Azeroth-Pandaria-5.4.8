-- Exact active rows backed up before 2026-07-31 correction.
-- Restore only the removed bindings; no spell or item data was deleted.
INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(26013, 'spell_timeless_isle_crane_wings'),
(63093, 'spell_mage_mirror_image'),
(88091, 'spell_mage_mirror_image'),
(88092, 'spell_mage_mirror_image');
