-- Bind the three raid/party stat buffs to this core's existing 5.4.8 scripts.
UPDATE `spell_script_names`
SET `ScriptName`='spell_dru_mark_of_the_wild'
WHERE `spell_id`=1126 AND `ScriptName`='spell_dru_mark_of_the_wild_stats';

UPDATE `spell_script_names`
SET `ScriptName`='spell_mage_arcane_brilliance'
WHERE `spell_id`=1459 AND `ScriptName`='spell_mage_arcane_brilliance_stats';

UPDATE `spell_script_names`
SET `ScriptName`='spell_pri_power_word_fortitude'
WHERE `spell_id`=21562 AND `ScriptName`='spell_pri_power_word_fortitude_stats';
