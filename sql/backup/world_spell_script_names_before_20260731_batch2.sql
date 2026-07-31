-- Exact active rows backed up before the 2026-07-31 spell binding batch 2.
INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(108939, 'spell_pri_glyph_of_levitate'),
(18461, 'spell_rog_vanish'),
(125084, 'spell_monk_charging_ox_wave');

-- Undo the new correct Charging Ox Wave association if a full rollback is required.
DELETE FROM `spell_script_names`
WHERE `spell_id` = 119392
  AND `ScriptName` = 'spell_monk_charging_ox_wave';
