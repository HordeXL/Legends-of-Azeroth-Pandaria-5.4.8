-- Selected low-risk SkyFire 5.4.8 world fixes.
--
-- Source: C:\wamp64\www\SkyFire_548\sql\updates\world
-- Notes:
-- - This file intentionally avoids table rebuilds and broad schema rewrites.
-- - The large 2026_06_22_world_03.sql loot rewrite is intentionally not included.

-- 2024_09_08_world_00.sql
-- Stolen Malt Sack
INSERT INTO `gameobject_template_addon` (`entry`, `flags`) VALUES
(210001, 4)
ON DUPLICATE KEY UPDATE `flags` = VALUES(`flags`);

DELETE FROM `gameobject_loot_template` WHERE `entry` = 40870;
INSERT INTO `gameobject_loot_template` (`entry`, `item`, `ChanceOrQuestChance`) VALUES
(40870, 77033, -100);

-- 2025_02_02_world_00.sql
-- Quest 12636 questender correction.
DELETE FROM `creature_questender` WHERE `quest` = 12636;
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(25462, 12636);

-- 2026_06_22_world_01.sql
-- Clear invalid kill-credit references that worldserver drops at runtime.
UPDATE `creature_template`
SET `KillCredit2` = 0
WHERE `entry` IN (71292, 71293)
  AND `KillCredit2` = 71066;

-- Remove graveyard subzone rows that worldserver skips during startup.
DELETE FROM `game_graveyard_zone`
WHERE `id` IN (1692, 1693, 1694, 1695)
  AND `ghost_zone` IN (4756, 4757, 4758, 4759)
  AND `faction` = 0;

-- 2026_06_22_world_02.sql
-- Restore missing Timeless Isle lootid links only when they are still empty.
UPDATE `creature_template`
SET `lootid` = `entry`
WHERE `entry` IN (
    71864, 71908, 71919, 72033, 72045, 72048, 72049, 72193, 72245, 72970,
    73160, 73161, 73163, 73166, 73173, 73279, 73281, 73282, 73703, 73704
)
  AND `lootid` = 0;

-- Remove two unused loot rows that have no matching creature_template entry.
DELETE FROM `creature_loot_template`
WHERE `entry` IN (68026, 68027)
  AND `item` = 92499
  AND `mincountOrRef` = -100;

-- 2026_06_27_world_02.sql
-- Bellygrub (345): remove three stacked duplicate spawns in Redridge Mountains.
DELETE FROM `creature` WHERE `guid` IN (89480, 89585, 89611) AND `id` = 345;

-- 2026_07_05_world_00.sql
-- Add loot for Jitter's Bugs quest (NPC 45582, item 60207).
UPDATE `creature_template` SET `lootid` = 45582 WHERE `entry` = 45582;
DELETE FROM `creature_loot_template` WHERE `entry` = 45582 AND `item` = 60207;
INSERT INTO `creature_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES
(45582, 60207, -100, 1, 0, 1, 1);

-- Prevent Jitters and Oliver Harris from disappearing after turning in quest 26721.
UPDATE `spell_area`
SET `quest_end` = 0, `quest_end_status` = 0
WHERE `spell` = 49416
  AND `quest_start` = 26717;

-- 2026_07_05_world_01.sql
-- Quest 26391: Extinguishing Hope.
UPDATE `creature_template`
SET `flags_extra` = 128
WHERE `entry` = 42940;

DELETE FROM `creature_template_model` WHERE `CreatureID` = 42940;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(42940, 0, 11686, 1, 1, 18414);
