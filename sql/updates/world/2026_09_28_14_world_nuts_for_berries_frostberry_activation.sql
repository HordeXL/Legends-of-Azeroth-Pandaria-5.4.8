-- Nuts for Berries (11912): explicitly associate Frostberry Bushes with the
-- quest so the client receives sparkle and activation flags while it is active.
UPDATE `gameobject_template`
SET `data8` = 11912
WHERE `entry` = 188113
  AND `type` = 3;
