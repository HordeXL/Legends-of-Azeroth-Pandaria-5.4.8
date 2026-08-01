-- Build 18414 handles Shaman Mail Specialization through
-- SpecializationSpells.dbc: Elemental receives 86108, Enhancement 86099, and
-- Restoration 86100. Spell 86529 has no aura for the old AuraScript hooks.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 86529
  AND `ScriptName` = 'spell_sha_mail_specialization';
