-- Exact, idempotent rollback for
-- 2026_07_30_01_world_split_cataclysm_cross_map_creature_pool.sql.

SET @cataclysm_creature_rollback_backup_ok :=
(
    SELECT
        (SELECT COUNT(*)
         FROM `_backup_pool_creature_manifest_cataclysm_cross_map_20260730`) = 5
        AND
        (SELECT COUNT(*)
         FROM `_backup_pool_template_cataclysm_cross_map_20260730`) = 1
        AND
        (SELECT COUNT(*)
         FROM `_backup_pool_creature_cataclysm_cross_map_20260730`) = 5
);

SET @cataclysm_creature_rollback_members_ok :=
(
    SELECT COUNT(*) = 5
       AND SUM(`pc`.`pool_entry` = `b`.`pool_entry`
               OR `pc`.`pool_entry` = `m`.`new_pool`) = 5
       AND SUM(`pc`.`chance` = `b`.`chance`) = 5
       AND SUM(`pc`.`description` <=> `b`.`description`) = 5
    FROM `_backup_pool_creature_cataclysm_cross_map_20260730` AS `b`
    INNER JOIN `_backup_pool_creature_manifest_cataclysm_cross_map_20260730` AS `m`
        ON `m`.`guid` = `b`.`guid`
    INNER JOIN `pool_creature` AS `pc` ON `pc`.`guid` = `b`.`guid`
);

SET @cataclysm_creature_rollback_targets_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template`
    WHERE (`entry` = 230010
           AND (`max_limit` <> 2
                OR `description` <> 'Cataclysm rare elite bosses (map 1)'))
       OR (`entry` = 330010
           AND (`max_limit` <> 1
                OR `description` <> 'Cataclysm rare elite bosses (map 646)'))
);

SET @cataclysm_creature_rollback_no_foreign_ok :=
(
    SELECT
        (SELECT COUNT(*)
         FROM `pool_creature` AS `pc`
         LEFT JOIN `_backup_pool_creature_manifest_cataclysm_cross_map_20260730` AS `m`
             ON `m`.`guid` = `pc`.`guid`
            AND `m`.`new_pool` = `pc`.`pool_entry`
         WHERE `pc`.`pool_entry` IN (230010,330010)
           AND `m`.`guid` IS NULL) = 0
        AND
        (SELECT COUNT(*)
         FROM `pool_gameobject`
         WHERE `pool_entry` IN (230010,330010)) = 0
        AND
        (SELECT COUNT(*)
         FROM `pool_quest`
         WHERE `pool_entry` IN (230010,330010)) = 0
        AND
        (SELECT COUNT(*)
         FROM `pool_pool`
         WHERE `pool_id` IN (230010,330010)
            OR `mother_pool` IN (230010,330010)) = 0
);

SET @cataclysm_creature_rollback_ok :=
    @cataclysm_creature_rollback_backup_ok
    AND @cataclysm_creature_rollback_members_ok
    AND @cataclysm_creature_rollback_targets_ok
    AND @cataclysm_creature_rollback_no_foreign_ok;

START TRANSACTION;

UPDATE `pool_creature` AS `pc`
INNER JOIN `_backup_pool_creature_cataclysm_cross_map_20260730` AS `b`
    ON `b`.`guid` = `pc`.`guid`
INNER JOIN `_backup_pool_creature_manifest_cataclysm_cross_map_20260730` AS `m`
    ON `m`.`guid` = `pc`.`guid`
SET `pc`.`pool_entry` = `b`.`pool_entry`,
    `pc`.`chance` = `b`.`chance`,
    `pc`.`description` = `b`.`description`
WHERE @cataclysm_creature_rollback_ok = 1
  AND (`pc`.`pool_entry` = `b`.`pool_entry`
       OR `pc`.`pool_entry` = `m`.`new_pool`);

DELETE `pt`
FROM `pool_template` AS `pt`
WHERE @cataclysm_creature_rollback_ok = 1
  AND `pt`.`entry` IN (230010,330010)
  AND NOT EXISTS
      (SELECT 1 FROM `pool_pool` AS `pp`
       WHERE `pp`.`pool_id` = `pt`.`entry`
          OR `pp`.`mother_pool` = `pt`.`entry`)
  AND NOT EXISTS
      (SELECT 1 FROM `pool_creature` AS `pc`
       WHERE `pc`.`pool_entry` = `pt`.`entry`)
  AND NOT EXISTS
      (SELECT 1 FROM `pool_gameobject` AS `pg`
       WHERE `pg`.`pool_entry` = `pt`.`entry`)
  AND NOT EXISTS
      (SELECT 1 FROM `pool_quest` AS `pq`
       WHERE `pq`.`pool_entry` = `pt`.`entry`);

COMMIT;

SELECT @cataclysm_creature_rollback_ok AS `rollback_guard`,
       (SELECT COUNT(*)
        FROM `_backup_pool_creature_manifest_cataclysm_cross_map_20260730`)
           AS `manifest_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_template_cataclysm_cross_map_20260730`)
           AS `template_backup_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_creature_cataclysm_cross_map_20260730`)
           AS `member_backup_rows`,
       (SELECT COUNT(*)
        FROM `pool_creature` AS `pc`
        INNER JOIN `_backup_pool_creature_cataclysm_cross_map_20260730` AS `b`
            ON `b`.`guid` = `pc`.`guid`
        WHERE `pc`.`pool_entry` = `b`.`pool_entry`)
           AS `restored_rows`;
