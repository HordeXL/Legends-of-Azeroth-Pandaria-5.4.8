-- Encasing Shadows (92023) is a native MOD_ROOT aura in build 18414.
-- The encounter AI applies that aura directly; it has no SCRIPT_EFFECT for
-- the inherited SpellScript hook to process. Preserve the spell and encounter
-- logic and remove only the impossible script association.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 92023
  AND `ScriptName` = 'spell_lord_victor_nefarius_encasing_shadows';
