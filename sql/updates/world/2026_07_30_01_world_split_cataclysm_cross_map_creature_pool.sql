-- Split Cataclysm rare elite pool 30010 by map.
-- All five pool_creature rows, chances and descriptions are preserved.
-- Pool 210 is intentionally excluded: its only map-1 member has chance 12,
-- and no authentic source for the missing same-map pool members was found.

CREATE TABLE IF NOT EXISTS `_backup_pool_creature_manifest_cataclysm_cross_map_20260730`
(
    `guid` INT UNSIGNED NOT NULL,
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_pool` MEDIUMINT UNSIGNED NOT NULL,
    `new_max_limit` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`guid`),
    KEY (`old_pool`,`map_id`)
);

INSERT INTO `_backup_pool_creature_manifest_cataclysm_cross_map_20260730`
(`guid`,`old_pool`,`map_id`,`new_pool`,`new_max_limit`) VALUES
(317090,30010,0,30010,2),
(371485,30010,0,30010,2),
(318795,30010,1,230010,2),
(371477,30010,1,230010,2),
(371491,30010,646,330010,1)
ON DUPLICATE KEY UPDATE
    `old_pool` = VALUES(`old_pool`),
    `map_id` = VALUES(`map_id`),
    `new_pool` = VALUES(`new_pool`),
    `new_max_limit` = VALUES(`new_max_limit`);

CREATE TABLE IF NOT EXISTS `_backup_pool_template_cataclysm_cross_map_20260730`
LIKE `pool_template`;

INSERT INTO `_backup_pool_template_cataclysm_cross_map_20260730`
SELECT `pt`.*
FROM `pool_template` AS `pt`
WHERE `pt`.`entry` = 30010
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_pool_template_cataclysm_cross_map_20260730` AS `b`
       WHERE `b`.`entry` = `pt`.`entry`);

CREATE TABLE IF NOT EXISTS `_backup_pool_creature_cataclysm_cross_map_20260730`
LIKE `pool_creature`;

INSERT INTO `_backup_pool_creature_cataclysm_cross_map_20260730`
SELECT `pc`.*
FROM `pool_creature` AS `pc`
INNER JOIN `_backup_pool_creature_manifest_cataclysm_cross_map_20260730` AS `m`
    ON `m`.`guid` = `pc`.`guid`
WHERE `pc`.`pool_entry` = `m`.`old_pool`
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_pool_creature_cataclysm_cross_map_20260730` AS `b`
       WHERE `b`.`guid` = `pc`.`guid`);

SET @cataclysm_creature_manifest_ok :=
(
    SELECT COUNT(*) = 5
       AND SUM(`old_pool` = 30010) = 5
       AND SUM(`map_id` = 0 AND `new_pool` = 30010) = 2
       AND SUM(`map_id` = 1 AND `new_pool` = 230010) = 2
       AND SUM(`map_id` = 646 AND `new_pool` = 330010) = 1
    FROM `_backup_pool_creature_manifest_cataclysm_cross_map_20260730`
);

SET @cataclysm_creature_template_backup_ok :=
(
    SELECT COUNT(*) = 1
       AND SUM(`entry` = 30010
               AND `max_limit` = 2
               AND `description` = 'Cataclysm rare elite bosses') = 1
    FROM `_backup_pool_template_cataclysm_cross_map_20260730`
);

SET @cataclysm_creature_member_backup_ok :=
(
    SELECT COUNT(*) = 5
       AND SUM(`pool_entry` = 30010
               AND `chance` = 0
               AND `description` LIKE 'Cataclysm rare bosses - %') = 5
    FROM `_backup_pool_creature_cataclysm_cross_map_20260730`
);

SET @cataclysm_creature_maps_ok :=
(
    SELECT COUNT(*) = 5
       AND SUM(`c`.`map` = `m`.`map_id`) = 5
    FROM `_backup_pool_creature_manifest_cataclysm_cross_map_20260730` AS `m`
    INNER JOIN `creature` AS `c` ON `c`.`guid` = `m`.`guid`
);

SET @cataclysm_creature_no_upper_refs_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_pool`
    WHERE `pool_id` = 30010
       OR `mother_pool` = 30010
);

SET @cataclysm_creature_targets_ok :=
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

SET @cataclysm_creature_no_foreign_targets_ok :=
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

SET @cataclysm_creature_original_state_ok :=
(
    SELECT COUNT(*) = 5
       AND SUM(`pc`.`pool_entry` = `b`.`pool_entry`) = 5
       AND SUM(`pc`.`chance` = `b`.`chance`) = 5
       AND SUM(`pc`.`description` <=> `b`.`description`) = 5
    FROM `_backup_pool_creature_cataclysm_cross_map_20260730` AS `b`
    INNER JOIN `pool_creature` AS `pc` ON `pc`.`guid` = `b`.`guid`
);

SET @cataclysm_creature_final_state_ok :=
(
    SELECT COUNT(*) = 5
       AND SUM(`pc`.`pool_entry` = `m`.`new_pool`) = 5
       AND SUM(`pc`.`chance` = `b`.`chance`) = 5
       AND SUM(`pc`.`description` <=> `b`.`description`) = 5
    FROM `_backup_pool_creature_cataclysm_cross_map_20260730` AS `b`
    INNER JOIN `_backup_pool_creature_manifest_cataclysm_cross_map_20260730` AS `m`
        ON `m`.`guid` = `b`.`guid`
    INNER JOIN `pool_creature` AS `pc` ON `pc`.`guid` = `b`.`guid`
);

SET @cataclysm_creature_apply_ok :=
    @cataclysm_creature_manifest_ok
    AND @cataclysm_creature_template_backup_ok
    AND @cataclysm_creature_member_backup_ok
    AND @cataclysm_creature_maps_ok
    AND @cataclysm_creature_no_upper_refs_ok
    AND @cataclysm_creature_targets_ok
    AND @cataclysm_creature_no_foreign_targets_ok
    AND (@cataclysm_creature_original_state_ok
         OR @cataclysm_creature_final_state_ok);

START TRANSACTION;

INSERT INTO `pool_template` (`entry`,`max_limit`,`description`)
SELECT 230010,2,'Cataclysm rare elite bosses (map 1)'
FROM DUAL
WHERE @cataclysm_creature_apply_ok = 1
  AND NOT EXISTS
      (SELECT 1 FROM `pool_template` WHERE `entry` = 230010);

INSERT INTO `pool_template` (`entry`,`max_limit`,`description`)
SELECT 330010,1,'Cataclysm rare elite bosses (map 646)'
FROM DUAL
WHERE @cataclysm_creature_apply_ok = 1
  AND NOT EXISTS
      (SELECT 1 FROM `pool_template` WHERE `entry` = 330010);

UPDATE `pool_creature` AS `pc`
INNER JOIN `_backup_pool_creature_manifest_cataclysm_cross_map_20260730` AS `m`
    ON `m`.`guid` = `pc`.`guid`
INNER JOIN `_backup_pool_creature_cataclysm_cross_map_20260730` AS `b`
    ON `b`.`guid` = `pc`.`guid`
SET `pc`.`pool_entry` = `m`.`new_pool`
WHERE @cataclysm_creature_apply_ok = 1
  AND (`pc`.`pool_entry` = `b`.`pool_entry`
       OR `pc`.`pool_entry` = `m`.`new_pool`);

COMMIT;

SELECT @cataclysm_creature_apply_ok AS `apply_guard`,
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
        INNER JOIN `_backup_pool_creature_manifest_cataclysm_cross_map_20260730` AS `m`
            ON `m`.`guid` = `pc`.`guid`
        WHERE `pc`.`pool_entry` = `m`.`new_pool`)
           AS `correct_final_rows`;
