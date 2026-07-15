-- These references exist in the preserved pre-fix world dumps, but their
-- referenced quest, creature spawns, and trigger/effect spells do not. Remove
-- only the exact rows proven to be orphaned; do not infer replacement content.

DELETE FROM `creature_queststarter`
WHERE `id` = 69782 AND `quest` = 32592
  AND NOT EXISTS (SELECT 1 FROM `quest_template` WHERE `ID` = 32592);

DELETE FROM `creature_questender`
WHERE `id` = 69782 AND `quest` = 32592
  AND NOT EXISTS (SELECT 1 FROM `quest_template` WHERE `ID` = 32592);

DELETE gec FROM `game_event_creature` gec
WHERE gec.`eventEntry` = 31
  AND gec.`guid` IN (77232, 136675)
  AND NOT EXISTS (SELECT 1 FROM `creature` c WHERE c.`guid` = gec.`guid`);

DELETE FROM `spell_linked_spell`
WHERE (`spell_trigger` = 123262 AND `spell_effect` = 203754 AND `type` = 0)
   OR (`spell_trigger` = 200002 AND `spell_effect` = 200004 AND `type` = 0)
   OR (`spell_trigger` = 200003 AND `spell_effect` = 200005 AND `type` = 0);
