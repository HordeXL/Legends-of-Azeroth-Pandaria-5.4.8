-- Keep the restored Kologarn difficulty template compatible with its active
-- Build-15595 parent. The core requires npcflag to match between difficulty
-- variants. Both pre-fix world dumps preserve npcflag 16777216 on entry 32930.

START TRANSACTION;

UPDATE `creature_template` parent
JOIN `creature_template` child
  ON child.`entry` = parent.`difficulty_entry_1`
SET child.`npcflag` = parent.`npcflag`
WHERE parent.`entry` = 32930
  AND parent.`difficulty_entry_1` = 33909
  AND parent.`VerifiedBuild` = 15595
  AND child.`entry` = 33909
  AND child.`name` = 'Kologarn (1)'
  AND child.`VerifiedBuild` = 15595
  AND child.`npcflag` = 0
  AND parent.`npcflag` = 16777216;

COMMIT;
