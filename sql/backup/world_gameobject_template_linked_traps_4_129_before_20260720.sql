-- Exact rollback for 2026_07_20_06_world_restore_linked_traps_4_129.sql.
-- It runs only while both restored templates and the addon row still match the
-- state produced by that update.

START TRANSACTION;

SET @linked_trap_templates_corrected :=
(
    SELECT COUNT(*)
    FROM `gameobject_template`
    WHERE
        (`entry` = 4
         AND `type` = 6 AND `displayId` = 0 AND `name` = 'Bonfire Damage'
         AND `size` = 1
         AND `data0` = 0 AND `data1` = 1 AND `data2` = 3 AND `data3` = 7902
         AND `AIName` = '' AND `ScriptName` = '' AND `VerifiedBuild` = 0)
        OR
        (`entry` = 129
         AND `type` = 6 AND `displayId` = 0 AND `name` = 'Naxx Teleporter trap'
         AND `size` = 1
         AND `data0` = 0 AND `data1` = 1 AND `data2` = 0 AND `data3` = 64446
         AND `AIName` = '' AND `ScriptName` = '' AND `VerifiedBuild` = 0)
);

SET @linked_trap_addon_corrected :=
(
    SELECT COUNT(*)
    FROM `gameobject_template_addon`
    WHERE `entry` = 4 AND `faction` = 14 AND `flags` = 0
      AND `mingold` = 0 AND `maxgold` = 0
);

SET @linked_trap_corrected_state_ok :=
    @linked_trap_templates_corrected = 2 AND @linked_trap_addon_corrected = 1;

UPDATE `gameobject_template`
SET `type` = 0,
    `displayId` = 7947,
    `name` = 'unk name',
    `data0` = 0,
    `data1` = 0,
    `data2` = 0,
    `data3` = 0,
    `VerifiedBuild` = 18414
WHERE `entry` = 4 AND @linked_trap_corrected_state_ok = 1;

UPDATE `gameobject_template`
SET `type` = 0,
    `displayId` = 9306,
    `name` = 'unk name',
    `data0` = 0,
    `data1` = 0,
    `data2` = 0,
    `data3` = 0,
    `VerifiedBuild` = 18414
WHERE `entry` = 129 AND @linked_trap_corrected_state_ok = 1;

UPDATE `gameobject_template_addon`
SET `faction` = 0
WHERE `entry` = 4 AND @linked_trap_corrected_state_ok = 1;

COMMIT;
