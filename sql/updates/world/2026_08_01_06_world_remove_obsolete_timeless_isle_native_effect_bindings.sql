-- Build 18414 implements Burning Fury directly as periodic fire damage plus
-- melee/ranged haste, and Cauterize as a percentage heal plus periodic
-- percentage damage. Remove only the obsolete script bindings that expect a
-- periodic-dummy aura absent from both spells.

DELETE FROM `spell_script_names`
WHERE (`spell_id` = 147703 AND `ScriptName` = 'spell_timeless_isle_burning_fury')
   OR (`spell_id` = 147997 AND `ScriptName` = 'spell_timeless_isle_cauterize');
