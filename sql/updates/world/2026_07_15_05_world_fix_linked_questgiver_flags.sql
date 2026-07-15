-- Add only UNIT_NPC_FLAG_QUESTGIVER (0x2) to NPCs that already have a
-- concrete queststarter/questender relation. Preserve every existing flag.

START TRANSACTION;

UPDATE `creature_template` ct
SET ct.`npcflag` = ct.`npcflag` | 2
WHERE ct.`entry` = 1362
  AND ct.`npcflag` = 4224
  AND EXISTS (SELECT 1 FROM `creature_queststarter` qs WHERE qs.`id` = 1362 AND qs.`quest` = 7062)
  AND EXISTS (SELECT 1 FROM `quest_template` q WHERE q.`Id` = 7062);

UPDATE `creature_template` ct
SET ct.`npcflag` = ct.`npcflag` | 2
WHERE ct.`entry` = 58507
  AND ct.`npcflag` = 1
  AND EXISTS (SELECT 1 FROM `creature_questender` qe WHERE qe.`id` = 58507 AND qe.`quest` = 31713)
  AND EXISTS (SELECT 1 FROM `quest_template` q WHERE q.`Id` = 31713);

UPDATE `creature_template` ct
SET ct.`npcflag` = ct.`npcflag` | 2
WHERE ct.`entry` = 73136
  AND ct.`npcflag` = 0
  AND EXISTS (SELECT 1 FROM `creature_questender` qe WHERE qe.`id` = 73136 AND qe.`quest` = 33138)
  AND EXISTS (SELECT 1 FROM `quest_template` q WHERE q.`Id` = 33138);

COMMIT;
