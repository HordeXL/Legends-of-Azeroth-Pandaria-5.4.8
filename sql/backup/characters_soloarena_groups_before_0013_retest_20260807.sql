-- Exact character-database backup for the two staged SoloArena test groups that
-- remained after the pre-revision 0013 WorldServer was stopped on 2026-08-07.
--
-- Database: characters (use the CharacterDatabaseInfo target)
-- Group 1: Palstest (2205) + Patrie (603)
-- Group 2: Alaniel (1175) + Idonia (485)
-- group_instance contained no rows for group GUID 1 or 2.
--
-- This file restores only these exact rows. It is not an update to apply during
-- normal server startup.

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

COMMIT;
