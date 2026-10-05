-- Protect the stationary Riko quest giver for Scouting Report: Hostile Natives.
-- UNIT_FLAG_IMMUNE_TO_NPC prevents hostile NPCs from selecting/attacking him.
-- Preserve faction, player interaction and the separate story/combat Riko entries.
START TRANSACTION;
UPDATE `creature_template` SET `unit_flags`=`unit_flags` | 512 WHERE `entry`=55648;
-- Spawn flags override template flags when nonzero, so protect both sources.
UPDATE `creature` SET `unit_flags`=`unit_flags` | 512 WHERE `id`=55648;
COMMIT;
