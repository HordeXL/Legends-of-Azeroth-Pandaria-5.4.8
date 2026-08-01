-- Rebind Omega Stance Spider effect 77127 to the source-backed handler.
-- Build 18414 defines effect 0 as SPELL_EFFECT_DUMMY with targets 18/72;
-- the old spell_omega_stance_spider handler incorrectly expected target 86.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 77127
  AND `ScriptName` IN
      ('spell_omega_stance_spider', 'spell_omega_stance_spider_effect');

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(77127, 'spell_omega_stance_spider_effect');
