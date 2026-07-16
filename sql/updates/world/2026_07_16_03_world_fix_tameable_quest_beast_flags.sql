-- SkyFire 5.4.8 e160430ae2: restore normal portrait/aggro behavior for
-- tameable quest beasts that were incorrectly marked with the unknown high bit.
-- This update is deliberately guarded by the exact old values and verified builds.

START TRANSACTION;

UPDATE `creature_template`
SET `type_flags` = 1,
    `dynamicflags` = 4
WHERE `entry` IN
(
    728, 731, 1225, 1961, 1994, 3281, 7319, 7977, 9622, 10737,
    10806, 14661, 18257, 18707, 21515, 23873, 26838, 39385, 40581,
    41420, 45450, 47053, 47687, 50044, 56357, 57421, 59037, 60203,
    60401, 63767, 65612
)
  AND `type_flags` = 2147483649
  AND `dynamicflags` = 0
  AND `VerifiedBuild` IN (15595, 18414);

COMMIT;
