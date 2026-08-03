-- Spell 203754 is not present in the 5.4.8 client spell data and is not a
-- Prayer of Mending spell. Keep the valid 123262 -> 41637 link unchanged and
-- remove only the exact invalid row restored by 2026_07_15_01.

DELETE FROM `spell_linked_spell`
WHERE `spell_trigger` = 123262
  AND `spell_effect` = 203754
  AND `type` = 0
  AND `comment` = 'Prayer of Mending server-side trigger';
