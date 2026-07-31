-- Exact active Gateway rows backed up before the 2026-08-01 loader split.
INSERT IGNORE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(113886, 'spell_warl_demonic_gateway_summon'),
(113890, 'spell_warl_demonic_gateway_summon');

DELETE FROM `spell_script_names`
WHERE (`spell_id` = 113886 AND `ScriptName` = 'spell_warl_demonic_gateway_summon_green')
   OR (`spell_id` = 113890 AND `ScriptName` = 'spell_warl_demonic_gateway_summon_purple');
