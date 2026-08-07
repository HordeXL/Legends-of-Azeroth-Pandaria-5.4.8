-- Exact character-database backup for the staged SoloArena state left by the
-- Tol'viron Arena crash on 2026-08-07 at 11:32:35.
--
-- Database: characters (use the CharacterDatabaseInfo target)
-- Group 1: Palstest (2205) + Patrie (603)
-- Group 2: Alaniel (1175) + Idonia (485)
-- group_instance contained no rows for group GUID 1 or 2.
-- All four characters had online=1 after the process crash.
--
-- This restores only the rows/status changed by the targeted crash cleanup.
-- It is not a normal startup update.

START TRANSACTION;

INSERT INTO `groups`
    (`guid`, `leaderGuid`, `lootMethod`, `looterGuid`, `lootThreshold`,
     `icon1`, `icon2`, `icon3`, `icon4`, `icon5`, `icon6`, `icon7`, `icon8`,
     `groupType`, `difficulty`, `raiddifficulty`, `slot`)
VALUES
    (1, 2205, 3, 2205, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 0),
    (2, 1175, 3, 1175, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 3, 0);

INSERT INTO `group_member`
    (`guid`, `memberGuid`, `memberFlags`, `subgroup`, `roles`)
VALUES
    (1, 603, 0, 0, 0),
    (1, 2205, 0, 0, 0),
    (2, 485, 0, 0, 0),
    (2, 1175, 0, 0, 0);

UPDATE `characters`
SET `online` = 1
WHERE `guid` IN (485, 603, 1175, 2205);

COMMIT;
