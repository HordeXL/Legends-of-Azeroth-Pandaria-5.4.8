-- Preserve this project's complete Galleon skinning set. The three exact rows
-- exist in both pre-fix world dumps and the active database. This corrective
-- update is needed only where the first applied _07 revision cleared skinloot.
-- No loot row is deleted or changed.

START TRANSACTION;

UPDATE `creature_template` AS ct
SET ct.`skinloot` = 62346
WHERE ct.`entry` = 62346
  AND ct.`name` = 'Galleon'
  AND ct.`lootid` = 0
  AND ct.`skinloot` = 0
  AND ct.`VerifiedBuild` = 18414
  AND 3 =
      (SELECT COUNT(*) FROM `skinning_loot_template` WHERE `entry` = 62346)
  AND EXISTS
      (SELECT 1 FROM `skinning_loot_template`
       WHERE `entry` = 62346 AND `item` = 72120
         AND `ChanceOrQuestChance` = 95 AND `groupid` = 1
         AND `mincountOrRef` = 1 AND `maxcount` = 5)
  AND EXISTS
      (SELECT 1 FROM `skinning_loot_template`
       WHERE `entry` = 62346 AND `item` = 72201
         AND `ChanceOrQuestChance` = 21 AND `groupid` = 1
         AND `mincountOrRef` = 1 AND `maxcount` = 1)
  AND EXISTS
      (SELECT 1 FROM `skinning_loot_template`
       WHERE `entry` = 62346 AND `item` = 79101
         AND `ChanceOrQuestChance` = 32 AND `groupid` = 1
         AND `mincountOrRef` = 1 AND `maxcount` = 2);

COMMIT;
