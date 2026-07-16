-- Galleon's old template used ordinary lootid 62346. Later matching SkyFire
-- 5.4.8 data uses personal loot, and the active world already has the complete
-- personal-loot owner row and 46 personal_loot_item rows.
-- Keep skinloot 62346 because this project's two preserved pre-fix databases
-- and active world contain the same complete three-row skinning loot set.
-- No loot/template row is deleted or overwritten.

START TRANSACTION;

UPDATE `creature_template` AS ct
SET ct.`lootid` = 0
WHERE ct.`entry` = 62346
  AND ct.`name` = 'Galleon'
  AND ct.`lootid` = 62346
  AND ct.`skinloot` = 62346
  AND ct.`VerifiedBuild` = 18414
  AND EXISTS
      (SELECT 1 FROM `personal_loot_template`
       WHERE `entry` = 62346 AND `quest` = 32098)
  AND 46 =
      (SELECT COUNT(*) FROM `personal_loot_item` WHERE `entry` = 62346)
  AND NOT EXISTS
      (SELECT 1 FROM `creature_loot_template` WHERE `entry` = 62346);

COMMIT;
