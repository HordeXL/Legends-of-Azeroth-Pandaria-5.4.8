-- 108939 is the glyph aura checked by the 111758 Levitate cast script.
DELETE FROM `spell_script_names`
WHERE `spell_id` = 108939
  AND `ScriptName` = 'spell_pri_glyph_of_levitate';

-- 18461 is the non-aura Vanish trigger. Keep spell_rog_vanish_trigger on it.
DELETE FROM `spell_script_names`
WHERE `spell_id` = 18461
  AND `ScriptName` = 'spell_rog_vanish';

-- 119392 owns the cone target effects; 125084 is its destination visual.
DELETE FROM `spell_script_names`
WHERE `spell_id` = 125084
  AND `ScriptName` = 'spell_monk_charging_ox_wave';

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(119392, 'spell_monk_charging_ox_wave');
