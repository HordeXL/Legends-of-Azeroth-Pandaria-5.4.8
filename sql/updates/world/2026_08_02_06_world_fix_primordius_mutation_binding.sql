-- The player Mutagenic Pool path casts Mutation 136178. Its Build-18414
-- effect 0 is the SCRIPT_EFFECT consumed by spell_mutation_primordius.
-- Spell 136203 is the separate Living Fluid -> Primordius effect and has no
-- script effect. Move the inherited loader association to the player spell.

UPDATE `spell_script_names`
SET `spell_id` = 136178
WHERE `spell_id` = 136203
  AND `ScriptName` = 'spell_mutation_primordius';
