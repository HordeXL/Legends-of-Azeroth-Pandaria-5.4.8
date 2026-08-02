-- Marked for Death 137619 owns the effect-1 dummy aura watched by the C++
-- removal handler. It natively triggers cooldown modifier spell 140149.
-- The duplicate 140149 binding cannot execute the effect-1 dummy-aura hook.
-- Preserve the valid 137619 binding and its native 140149 trigger.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 140149
  AND `ScriptName` = 'spell_rog_marked_for_death';
