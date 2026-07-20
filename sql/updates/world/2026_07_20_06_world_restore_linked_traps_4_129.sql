-- Restore the two linked trap templates referenced by valid spell-focus/goober
-- templates.  The active 5.4.8 DB contains placeholder type-0 rows instead.
-- Sources:
--   TrinityCore/sql/old/7/world/01_2018_02_19/
--     2017_11_26_08_world_2016_11_02_02_world.sql
--   TDB_full_world_1200.26021_2026_02_06.sql
-- Local Build 18414 Spell.dbc contains both spell 7902 and spell 64446.

START TRANSACTION;

SET @linked_trap_templates_original :=
(
    SELECT COUNT(*)
    FROM `gameobject_template`
    WHERE
        (`entry` = 4
         AND `type` = 0 AND `displayId` = 7947 AND `name` = 'unk name'
         AND `size` = 1
         AND `data0` = 0 AND `data1` = 0 AND `data2` = 0
         AND `data3` = 0 AND `data4` = 0 AND `data5` = 0
         AND `data6` = 0 AND `data7` = 0 AND `data8` = 0
         AND `data9` = 0 AND `data10` = 0 AND `data11` = 0
         AND `data12` = 0
         AND `AIName` = '' AND `ScriptName` = '' AND `VerifiedBuild` = 18414)
        OR
        (`entry` = 129
         AND `type` = 0 AND `displayId` = 9306 AND `name` = 'unk name'
         AND `size` = 1
         AND `data0` = 0 AND `data1` = 0 AND `data2` = 0
         AND `data3` = 0 AND `data4` = 0 AND `data5` = 0
         AND `data6` = 0 AND `data7` = 0 AND `data8` = 0
         AND `data9` = 0 AND `data10` = 0 AND `data11` = 0
         AND `data12` = 0
         AND `AIName` = '' AND `ScriptName` = '' AND `VerifiedBuild` = 18414)
);

SET @linked_trap_addon_original :=
(
    SELECT COUNT(*)
    FROM `gameobject_template_addon`
    WHERE `entry` = 4 AND `faction` = 0 AND `flags` = 0
      AND `mingold` = 0 AND `maxgold` = 0
);

SET @linked_trap_original_state_ok :=
    @linked_trap_templates_original = 2 AND @linked_trap_addon_original = 1;

UPDATE `gameobject_template`
SET `type` = 6,
    `displayId` = 0,
    `name` = 'Bonfire Damage',
    `data0` = 3,
    `data1` = 7902,
    `VerifiedBuild` = 0
WHERE `entry` = 4 AND @linked_trap_original_state_ok = 1;

UPDATE `gameobject_template`
SET `type` = 6,
    `displayId` = 0,
    `name` = 'Naxx Teleporter trap',
    `data0` = 0,
    `data1` = 64446,
    `VerifiedBuild` = 0
WHERE `entry` = 129 AND @linked_trap_original_state_ok = 1;

UPDATE `gameobject_template_addon`
SET `faction` = 14
WHERE `entry` = 4 AND @linked_trap_original_state_ok = 1;

COMMIT;

