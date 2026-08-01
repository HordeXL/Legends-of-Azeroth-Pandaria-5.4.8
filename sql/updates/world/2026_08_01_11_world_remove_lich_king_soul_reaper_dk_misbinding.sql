-- Keep the correct Lich King encounter binding on 69409. Its effect 1 is
-- SPELL_AURA_PERIODIC_DAMAGE, not the periodic-dummy aura used by DK Soul Reaper.
-- The DK class script remains bound to 114866, 130735, and 130736.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 69409
  AND `ScriptName` = 'spell_dk_soul_reaper';
