-- The core applies the real client rated-battleground faction auras 81744 and
-- 81748. Trigger spells 200002 and 200003 do not exist in either the 5.4.8
-- client DBC or the custom spell_dbc, so these links can never execute.
-- Preserve the existing custom effect spell definitions 200004 and 200005.

DELETE FROM `spell_linked_spell`
WHERE (`spell_trigger` = 200002
       AND `spell_effect` = 200004
       AND `type` = 0
       AND `comment` = 'Alliance to Horde (tick)')
   OR (`spell_trigger` = 200003
       AND `spell_effect` = 200005
       AND `type` = 0
       AND `comment` = 'Horde to Alliance (tick)');
