-- Rollback for 2026_07_22_00_world_fix_legacy_pvp_vendors.sql.
--
-- The migration stores the exact 972 removed npc_vendor rows in the persistent
-- table `_backup_npc_vendor_699xx_shadowlands_20260722` before changing data.
-- Those rows use ExtendedCost 5962/5963/5964/5966.  They are valid for the
-- Shadowlands 9.1.0 client build 40120 vendor data, but the local MoP 5.4.8
-- ItemExtendedCost.db2 (Build 18273/18414 client data) ends at ID 5280.
-- The items themselves are older WotLK/Cataclysm PvP items and are not deleted.

START TRANSACTION;

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

-- Remove only the Relentless rows inserted by the migration.  All compared
-- source rows remain in npc_vendor and identify the exact item/cost pair.
DELETE `dst`
FROM `npc_vendor` AS `dst`
JOIN `npc_vendor` AS `src`
  ON `src`.`entry` = 33927
 AND `src`.`item` = `dst`.`item`
 AND `src`.`ExtendedCost` = `dst`.`ExtendedCost`
 AND `src`.`type` = `dst`.`type`
JOIN `_backup_npc_vendor_699xx_shadowlands_20260722` AS `affected`
  ON `affected`.`entry` = 69973
 AND `affected`.`item` = `dst`.`item`
WHERE `dst`.`entry` = 54653
  AND @legacy_pvp_backup_ok = 1;

DELETE `dst`
FROM `npc_vendor` AS `dst`
JOIN `npc_vendor` AS `src`
  ON `src`.`entry` = 34059
 AND `src`.`item` = `dst`.`item`
 AND `src`.`ExtendedCost` = `dst`.`ExtendedCost`
 AND `src`.`type` = `dst`.`type`
JOIN `_backup_npc_vendor_699xx_shadowlands_20260722` AS `affected`
  ON `affected`.`entry` = 69973
 AND `affected`.`item` = `dst`.`item`
WHERE `dst`.`entry` = 54657
  AND @legacy_pvp_backup_ok = 1;

DELETE `dst`
FROM `npc_vendor` AS `dst`
JOIN `npc_vendor` AS `src`
  ON `src`.`entry` = 34077
 AND `src`.`item` = `dst`.`item`
 AND `src`.`ExtendedCost` = `dst`.`ExtendedCost`
 AND `src`.`type` = `dst`.`type`
JOIN `_backup_npc_vendor_699xx_shadowlands_20260722` AS `affected`
  ON `affected`.`entry` = 69973
 AND `affected`.`item` = `dst`.`item`
WHERE `dst`.`entry` = 54660
  AND @legacy_pvp_backup_ok = 1;

-- Remove only the two exact MoP legacy-vendor spawns added in Dalaran.
DELETE FROM `creature`
WHERE @legacy_pvp_backup_ok = 1
  AND
  (
      (`id` = 69318 AND `map` = 571 AND `zoneId` = 4395 AND `areaId` = 4570
       AND ABS(`position_x` - 5756.75) < 0.01
       AND ABS(`position_y` - 588.0) < 0.01
       AND ABS(`position_z` - 615.052) < 0.01 AND `VerifiedBuild` = 18414)
   OR (`id` = 69321 AND `map` = 571 AND `zoneId` = 4395 AND `areaId` = 4570
       AND ABS(`position_x` - 5760.25) < 0.01
       AND ABS(`position_y` - 588.0) < 0.01
       AND ABS(`position_z` - 615.052) < 0.01 AND `VerifiedBuild` = 18414)
  );

-- Restore the exact cross-version rows.  They will again be ignored by the
-- 5.4.8 server and reproduce the original startup warnings; this is rollback,
-- not the recommended active state.
INSERT IGNORE INTO `npc_vendor`
SELECT *
FROM `_backup_npc_vendor_699xx_shadowlands_20260722`
WHERE @legacy_pvp_backup_ok = 1;

COMMIT;
