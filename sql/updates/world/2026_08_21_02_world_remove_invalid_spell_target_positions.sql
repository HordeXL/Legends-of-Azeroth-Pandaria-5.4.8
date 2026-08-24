-- Remove five spell_target_position records rejected by the 5.4.8
-- build-18414 spell data. Each delete is guarded by the complete preserved
-- row, so a later or independently corrected value is never removed.
--
-- Evidence:
-- * 49986 has no effect index 1.
-- * 66836, 66925 and 105002 summon through non-DB targets; their owning zone
--   scripts use explicit summon positions.
-- * 100679 has no effect index 2. Its former 4.3.4 DB destination used effect
--   0, but this core converts that effect to a dynamic destination and the
--   Firelands script directly summons Dreadflame at its computed floor point.
-- * none of the five rows exists in SFDB 548 release 25.001.

DELETE FROM `spell_target_position`
WHERE `id` = 49986 AND `effIndex` = 1 AND `target_map` = 571;

DELETE FROM `spell_target_position`
WHERE `id` = 66836 AND `effIndex` = 0 AND `target_map` = 654;

DELETE FROM `spell_target_position`
WHERE `id` = 66925 AND `effIndex` = 0 AND `target_map` = 654;

DELETE FROM `spell_target_position`
WHERE `id` = 100679 AND `effIndex` = 2 AND `target_map` = 720;

DELETE FROM `spell_target_position`
WHERE `id` = 105002 AND `effIndex` = 0 AND `target_map` = 860;
