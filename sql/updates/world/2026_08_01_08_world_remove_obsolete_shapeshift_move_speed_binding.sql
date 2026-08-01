-- Build 18414 already enforces the outdoors-only restriction for spell 23218
-- through SPELL_ATTR0_OUTDOORS_ONLY. Its old script always returned true and
-- bound DoCheckAreaTarget to a non-area aura, so the hook could never execute.

DELETE FROM `spell_script_names`
WHERE `spell_id` = 23218
  AND `ScriptName` = 'spell_dru_shapeshift_move_speed';
