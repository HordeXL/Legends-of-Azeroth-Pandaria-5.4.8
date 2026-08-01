-- Remove obsolete pre-MoP script bindings, preserving the spells themselves.
--
-- The Incanter's Absorption C++ scripts require spells 44394 and 44413, neither
-- of which exists in the active Build 18414 Spell.dbc. Trinity's 4.3.4 update
-- 2012_12_26_00_world_spell_script_names_434.sql had already removed these
-- script names. The current 5.4.8 spell effects do not match those old hooks.
DELETE FROM `spell_script_names`
WHERE (`spell_id` IN (11426, 116267)
       AND `ScriptName` = 'spell_mage_incanters_absorbtion_absorb')
   OR (`spell_id` IN (1463, 144318)
       AND `ScriptName` = 'spell_mage_incanters_absorbtion_manashield');

-- The old Last Stand script requires triggered spell 12976, absent from the
-- active Build 18414 Spell.dbc. In 5.4.8 spell 12975 already applies its own
-- SPELL_AURA_MOD_INCREASE_HEALTH_2 effect, so the legacy dummy-effect script
-- can never validate and must not be attached.
DELETE FROM `spell_script_names`
WHERE `spell_id` = 12975
  AND `ScriptName` = 'spell_warr_last_stand';
