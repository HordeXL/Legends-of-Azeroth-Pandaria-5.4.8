-- Exact affected-field backup before aligning Galleon with the final
-- matching-version SkyFire 5.4.8 personal-loot configuration.

START TRANSACTION;

UPDATE `creature_template`
SET `lootid` = 62346,
    `skinloot` = 62346
WHERE `entry` = 62346
  AND `name` = 'Galleon'
  AND `lootid` = 0
  AND `skinloot` = 0
  AND `VerifiedBuild` = 18414;

COMMIT;
