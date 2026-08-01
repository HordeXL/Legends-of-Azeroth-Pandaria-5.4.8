-- Build 18414 defines Devastating Arc 117006 as an effect-0 dummy cone that
-- natively triggers damage spell 116835 from effect 1. It has no aura effect,
-- so the inherited spell_devastating_arc AuraScript can never execute.
-- Preserve the native trigger chain and the valid 116835 target script; remove
-- only the impossible 117006 AuraScript association.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 117006
  AND `ScriptName` = 'spell_devastating_arc';
