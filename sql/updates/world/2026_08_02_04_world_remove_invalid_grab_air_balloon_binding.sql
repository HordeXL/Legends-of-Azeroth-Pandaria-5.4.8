-- spell_grab_air_balloon is implemented for spell 95247, whose effect 0 is
-- the APPLY_AURA hook used by the C++ loader. Spell 128815 instead uses its
-- native effect to trigger 105002 and cannot execute that loader hook.
-- Preserve the valid 95247 binding and the complete 128815 -> 105002 chain.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 128815
  AND `ScriptName` = 'spell_grab_air_balloon';
