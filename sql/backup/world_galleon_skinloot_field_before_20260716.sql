-- Exact affected-field backup before restoring the preserved Galleon
-- skinning-loot reference after the first _07 application set it to zero.

START TRANSACTION;

UPDATE `creature_template`
SET `skinloot` = 0
WHERE `entry` = 62346
  AND `name` = 'Galleon'
  AND `lootid` = 0
  AND `skinloot` = 62346
  AND `VerifiedBuild` = 18414;

COMMIT;
