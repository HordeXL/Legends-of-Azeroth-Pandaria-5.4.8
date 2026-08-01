-- 116779 is the controller aura which triggers the two scripted gas spells.
DELETE FROM `spell_script_names`
WHERE `spell_id` = 116779
  AND `ScriptName` IN ('spell_titan_gas', 'spell_titan_gas2');

-- 115399 is Chi Brew; the Healing Elixirs script remains on 122280.
DELETE FROM `spell_script_names`
WHERE `spell_id` = 115399
  AND `ScriptName` = 'spell_monk_healing_elixirs';
