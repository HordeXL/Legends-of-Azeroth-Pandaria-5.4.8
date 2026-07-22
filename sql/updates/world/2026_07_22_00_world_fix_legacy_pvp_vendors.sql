-- Replace cross-version legacy-PvP vendor costs with data already present and
-- valid for this project's MoP 5.4.8 client files.
--
-- Removed layer:
--   entries 69971/69973/69974/69975/69977/69978, 972 rows total;
--   ExtendedCost 5962/5963/5964/5966;
--   Trinity source data verified against Shadowlands 9.1.0 build 40120.
--   These IDs do not exist in local ItemExtendedCost.db2 (maximum ID 5280).
--
-- Replacement layer:
--   * Wrathful items are already fully sold by spawned legacy vendors.
--   * Relentless item/cost pairs are copied from the existing 33927/34059/34077
--     inventories to the already spawned MoP entries 54653/54657/54660.
--   * Kylo Kelwin 69318 and Herwin Steampop 69321 already have complete,
--     Build-18414-compatible S9-S11 armor/weapon inventories and are spawned in
--     their documented location, the Dalaran Underbelly.

-- CREATE TABLE performs an implicit commit in MySQL 5.7, so it must precede
-- the explicit transaction used for the data changes below.
CREATE TABLE IF NOT EXISTS `_backup_npc_vendor_699xx_shadowlands_20260722`
LIKE `npc_vendor`;

START TRANSACTION;

INSERT IGNORE INTO `_backup_npc_vendor_699xx_shadowlands_20260722`
SELECT *
FROM `npc_vendor`
WHERE `entry` IN (69971, 69973, 69974, 69975, 69977, 69978)
  AND `ExtendedCost` IN (5962, 5963, 5964, 5966);

SET @legacy_pvp_bad_rows_ok :=
(
    SELECT COUNT(*) = 972
       AND SUM(`ExtendedCost` = 5962) = 206
       AND SUM(`ExtendedCost` = 5963) = 308
       AND SUM(`ExtendedCost` = 5964) = 290
       AND SUM(`ExtendedCost` = 5966) = 168
    FROM `npc_vendor`
    WHERE `entry` IN (69971, 69973, 69974, 69975, 69977, 69978)
      AND `ExtendedCost` IN (5962, 5963, 5964, 5966)
);

SET @legacy_pvp_backup_ok :=
(
    SELECT COUNT(*) = 972
       AND SUM(`ExtendedCost` = 5962) = 206
       AND SUM(`ExtendedCost` = 5963) = 308
       AND SUM(`ExtendedCost` = 5964) = 290
       AND SUM(`ExtendedCost` = 5966) = 168
    FROM `_backup_npc_vendor_699xx_shadowlands_20260722`
    WHERE `entry` IN (69971, 69973, 69974, 69975, 69977, 69978)
      AND `ExtendedCost` IN (5962, 5963, 5964, 5966)
);

SET @legacy_pvp_548_sources_ok :=
(
    (SELECT COUNT(*) FROM `npc_vendor` AS `v`
      JOIN (SELECT DISTINCT `item` FROM `npc_vendor` WHERE `entry` = 69973) AS `t`
        ON `t`.`item` = `v`.`item`
     WHERE `v`.`entry` = 33927
       AND `v`.`ExtendedCost` BETWEEN 1 AND 5280) = 119
    AND
    (SELECT COUNT(*) FROM `npc_vendor` AS `v`
      JOIN (SELECT DISTINCT `item` FROM `npc_vendor` WHERE `entry` = 69973) AS `t`
        ON `t`.`item` = `v`.`item`
     WHERE `v`.`entry` = 34059
       AND `v`.`ExtendedCost` BETWEEN 1 AND 5280) = 40
    AND
    (SELECT COUNT(*) FROM `npc_vendor` AS `v`
      JOIN (SELECT DISTINCT `item` FROM `npc_vendor` WHERE `entry` = 69973) AS `t`
        ON `t`.`item` = `v`.`item`
     WHERE `v`.`entry` = 34077
       AND `v`.`ExtendedCost` BETWEEN 1 AND 5280) = 40
    AND (SELECT COUNT(*) FROM `npc_vendor` WHERE `entry` = 69318) = 485
    AND (SELECT COUNT(*) FROM `npc_vendor` WHERE `entry` = 69321) = 93
    AND (SELECT COUNT(*) FROM `npc_vendor`
         WHERE `entry` IN (69318, 69321)
           AND `ExtendedCost` NOT BETWEEN 1 AND 5280) = 0
    AND (SELECT COUNT(*) FROM `creature` WHERE `id` IN (54653, 54657, 54660)) = 3
    AND (SELECT COUNT(*) FROM `creature` WHERE `id` IN (69318, 69321)) = 0
    AND (SELECT COUNT(*) FROM `creature_template`
         WHERE `entry` IN (69318, 69321) AND (`npcflag` & 128) = 128) = 2
);

SET @legacy_pvp_destinations_clean :=
(
    (SELECT COUNT(*)
       FROM `npc_vendor` AS `dst`
       JOIN (SELECT DISTINCT `item` FROM `npc_vendor` WHERE `entry` = 69973) AS `t`
         ON `t`.`item` = `dst`.`item`
      WHERE `dst`.`entry` IN (54653, 54657, 54660)) = 0
);

SET @legacy_pvp_original_state_ok :=
    @legacy_pvp_bad_rows_ok = 1
    AND @legacy_pvp_backup_ok = 1
    AND @legacy_pvp_548_sources_ok = 1
    AND @legacy_pvp_destinations_clean = 1;

-- Nargle Lashcord in Dalaran: the 119 Relentless arena pieces.
INSERT IGNORE INTO `npc_vendor`
    (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `type`)
SELECT 54653, 0, `src`.`item`, `src`.`maxcount`, `src`.`incrtime`,
       `src`.`ExtendedCost`, `src`.`type`
FROM `npc_vendor` AS `src`
JOIN (SELECT DISTINCT `item` FROM `npc_vendor` WHERE `entry` = 69973) AS `affected`
  ON `affected`.`item` = `src`.`item`
WHERE `src`.`entry` = 33927
  AND `src`.`ExtendedCost` BETWEEN 1 AND 5280
  AND @legacy_pvp_original_state_ok = 1;

-- Faction quartermasters: the remaining 40 Relentless off-set pieces.
INSERT IGNORE INTO `npc_vendor`
    (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `type`)
SELECT 54657, 0, `src`.`item`, `src`.`maxcount`, `src`.`incrtime`,
       `src`.`ExtendedCost`, `src`.`type`
FROM `npc_vendor` AS `src`
JOIN (SELECT DISTINCT `item` FROM `npc_vendor` WHERE `entry` = 69973) AS `affected`
  ON `affected`.`item` = `src`.`item`
WHERE `src`.`entry` = 34059
  AND `src`.`ExtendedCost` BETWEEN 1 AND 5280
  AND @legacy_pvp_original_state_ok = 1;

INSERT IGNORE INTO `npc_vendor`
    (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `type`)
SELECT 54660, 0, `src`.`item`, `src`.`maxcount`, `src`.`incrtime`,
       `src`.`ExtendedCost`, `src`.`type`
FROM `npc_vendor` AS `src`
JOIN (SELECT DISTINCT `item` FROM `npc_vendor` WHERE `entry` = 69973) AS `affected`
  ON `affected`.`item` = `src`.`item`
WHERE `src`.`entry` = 34077
  AND `src`.`ExtendedCost` BETWEEN 1 AND 5280
  AND @legacy_pvp_original_state_ok = 1;

-- Patch-5.2 legacy vendors, placed beside the existing PvP vendors in the
-- Dalaran Underbelly.  GUID is auto-generated to avoid colliding with custom
-- and playerbot GUID ranges in this world.
INSERT INTO `creature`
    (`id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `phaseId`,
     `phaseGroup`, `modelid`, `equipment_id`, `position_x`, `position_y`,
     `position_z`, `orientation`, `spawntimesecs`, `spawntimesecs_max`,
     `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`,
     `MovementType`, `npcflag`, `npcflag2`, `unit_flags`, `unit_flags2`,
     `dynamicflags`, `ScriptName`, `walk_mode`, `VerifiedBuild`)
SELECT 69318, 571, 4395, 4570, 1, 1, 0, 0, 0, 0,
       5756.75, 588.0, 615.052, 3.141593, 120, 0, 0, 0, 1, 0,
       0, 0, 0, 0, 0, 0, '', 0, 18414
WHERE @legacy_pvp_original_state_ok = 1
  AND NOT EXISTS (SELECT 1 FROM `creature` WHERE `id` = 69318);

INSERT INTO `creature`
    (`id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `phaseId`,
     `phaseGroup`, `modelid`, `equipment_id`, `position_x`, `position_y`,
     `position_z`, `orientation`, `spawntimesecs`, `spawntimesecs_max`,
     `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`,
     `MovementType`, `npcflag`, `npcflag2`, `unit_flags`, `unit_flags2`,
     `dynamicflags`, `ScriptName`, `walk_mode`, `VerifiedBuild`)
SELECT 69321, 571, 4395, 4570, 1, 1, 0, 0, 0, 0,
       5760.25, 588.0, 615.052, 3.141593, 120, 0, 0, 0, 1, 0,
       0, 0, 0, 0, 0, 0, '', 0, 18414
WHERE @legacy_pvp_original_state_ok = 1
  AND NOT EXISTS (SELECT 1 FROM `creature` WHERE `id` = 69321);

-- Remove only the exact rows whose ExtendedCost is absent from this client.
-- Item templates and all valid 5.4.8 vendor rows remain untouched.
DELETE FROM `npc_vendor`
WHERE `entry` IN (69971, 69973, 69974, 69975, 69977, 69978)
  AND `ExtendedCost` IN (5962, 5963, 5964, 5966)
  AND @legacy_pvp_original_state_ok = 1;

COMMIT;
