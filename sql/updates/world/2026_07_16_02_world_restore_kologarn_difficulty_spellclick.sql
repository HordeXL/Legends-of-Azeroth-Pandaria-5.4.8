-- Restore the spell-click definition required by the Build-15595 Kologarn
-- difficulty template. The linked parent entry has the authoritative spell,
-- cast flags, and user type; no value is invented or overwritten here.

START TRANSACTION;

INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`)
SELECT child.`entry`, parent_click.`spell_id`, parent_click.`cast_flags`, parent_click.`user_type`
FROM `creature_template` parent
JOIN `creature_template` child
  ON child.`entry` = parent.`difficulty_entry_1`
JOIN `npc_spellclick_spells` parent_click
  ON parent_click.`npc_entry` = parent.`entry`
WHERE parent.`entry` = 32930
  AND parent.`difficulty_entry_1` = 33909
  AND parent.`VerifiedBuild` = 15595
  AND child.`entry` = 33909
  AND child.`name` = 'Kologarn (1)'
  AND child.`VerifiedBuild` = 15595
  AND (parent.`npcflag` & 16777216) <> 0
  AND child.`npcflag` = parent.`npcflag`
  AND NOT EXISTS (
    SELECT 1
    FROM `npc_spellclick_spells` existing
    WHERE existing.`npc_entry` = child.`entry`
      AND existing.`spell_id` = parent_click.`spell_id`
  );

COMMIT;
