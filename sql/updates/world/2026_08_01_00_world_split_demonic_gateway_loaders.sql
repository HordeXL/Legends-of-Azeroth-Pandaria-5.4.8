-- This core calls Register() before SpellScript::GetSpellInfo() is available.
DELETE FROM `spell_script_names`
WHERE `spell_id` IN (113886, 113890)
  AND `ScriptName` = 'spell_warl_demonic_gateway_summon';

INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(113886, 'spell_warl_demonic_gateway_summon_green'),
(113890, 'spell_warl_demonic_gateway_summon_purple');
