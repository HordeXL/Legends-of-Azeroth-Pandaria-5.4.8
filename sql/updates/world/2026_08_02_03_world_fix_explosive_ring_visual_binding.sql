-- The encounter defines and casts four Explosive Ring visual sizes:
-- 144191, 144192, 144193, and 144195. SpellMgr corrects those same four
-- effects to TARGET_DEST_CASTER for the shared destination-offset script.
-- The inherited fourth binding used adjacent but unrelated spell 144194.

UPDATE `spell_script_names`
SET `spell_id` = 144195
WHERE `spell_id` = 144194
  AND `ScriptName` = 'spell_paragon_explosive_ring_visual';
