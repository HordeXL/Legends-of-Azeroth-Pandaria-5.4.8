-- Build 18414 identifies 122852 as Imperial Vizier Zor'lok's Inhale and
-- 122853 as Blade Lord Ta'yak's Tempest Slash. The inherited association
-- therefore attaches spell_inhale to the wrong encounter spell.
--
-- Inhale 122852 already implements its required mechanic natively: effect 0
-- applies the 50% dummy aura, and SpellAuraOptions permits the aura to stack.
-- The C++ encounter reads those native stacks when scaling Exhale damage.
-- Keep Ta'yak's valid spell_tempest_slash association on 122853 unchanged.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 122853
  AND `ScriptName` = 'spell_inhale';
