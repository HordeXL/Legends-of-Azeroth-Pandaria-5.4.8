-- Build-18414 spell 123740 is the self-targeted periodic aura which triggers
-- spell 123742.  The actual area-entry target list filtered by
-- spell_dark_of_night_fixate belongs to triggered spell 123742.
-- Preserve the companion spell_tsulong_dark_of_night binding on 123742.

UPDATE `spell_script_names`
SET `spell_id` = 123742
WHERE `spell_id` = 123740
  AND `ScriptName` = 'spell_dark_of_night_fixate';
