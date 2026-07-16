-- Galleon's old Build-17688 template used ordinary lootid/skinloot 62346.
-- The final matching SkyFire 5.4.8 template has both fields set to zero and
-- uses personal loot. The active world already has the complete personal
-- loot owner row and 46 personal_loot_item rows.
-- No loot/template row is deleted or overwritten.

START TRANSACTION;

UPDATE `creature_template` AS ct
SET ct.`lootid` = 0,
    ct.`skinloot` = 0
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
