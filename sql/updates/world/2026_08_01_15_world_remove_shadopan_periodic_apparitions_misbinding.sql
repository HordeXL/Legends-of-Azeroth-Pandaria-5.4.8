-- Apparitions (111698) is a native PERIODIC_TRIGGER_SPELL aura that triggers
-- absorb spell 112060. It has neither the area target nor SCHOOL_ABSORB aura
-- expected by the inherited combined script. Preserve the aura, trigger
-- chain, and valid 112060 association; remove only the impossible 111698
-- association.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 111698
  AND `ScriptName` = 'spell_shadopan_apparitions';
