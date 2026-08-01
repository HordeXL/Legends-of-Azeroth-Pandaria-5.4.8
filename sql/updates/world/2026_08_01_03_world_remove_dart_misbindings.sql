-- Remove only spell_dart associations whose Build-18414 effects cannot match
-- the script's TARGET_UNIT_SRC_AREA_ENTRY target hook.
--
-- 119311 is the Stream of Blades cone-damage spell. Its separate, compatible
-- spell_dart_damage association is intentionally preserved.
-- 119338 is a self-targeted aura, not a sword-launcher selector.
-- 120142 is Dart, a hostile area-damage spell, not a sword-launcher selector.
-- The six compatible Stream of Blades selector bindings remain untouched.
DELETE FROM `spell_script_names`
WHERE `ScriptName` = 'spell_dart'
  AND `spell_id` IN (119311, 119338, 120142);
