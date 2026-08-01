-- Trinity's original Emerald Dragons support script belongs to server-side
-- area trigger 25042. Spell 25040 is only the marker aura applied on death.

DELETE FROM `spell_script_names`
WHERE `ScriptName` = 'spell_mark_of_nature'
  AND `spell_id` IN (25040, 25042);

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(25042, 'spell_mark_of_nature');
