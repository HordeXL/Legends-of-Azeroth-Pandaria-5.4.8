-- Exact, idempotent rollback for
-- 2026_07_29_03_world_split_second_two_hundred_cross_map_master_pools.sql.

DROP TEMPORARY TABLE IF EXISTS `_tmp_second_200_master_rollback_maps_20260729`;
CREATE TEMPORARY TABLE `_tmp_second_200_master_rollback_maps_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    `child_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_mother`,`child_pool`,`map_id`)
);

INSERT INTO `_tmp_second_200_master_rollback_maps_20260729`
(`old_mother`,`child_pool`,`map_id`)
SELECT `b`.`mother_pool`,`b`.`pool_id`,`g`.`map`
FROM `_backup_pool_pool_second_200_master_20260729` AS `b`
INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`pool_entry` = `b`.`pool_id`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `pg`.`guid`
GROUP BY `b`.`mother_pool`,`b`.`pool_id`,`g`.`map`;

DROP TEMPORARY TABLE IF EXISTS `_tmp_second_200_master_rollback_splits_20260729`;
CREATE TEMPORARY TABLE `_tmp_second_200_master_rollback_splits_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_mother` MEDIUMINT UNSIGNED NOT NULL,
    `max_limit` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_mother`,`map_id`),
    UNIQUE KEY (`new_mother`)
);

INSERT INTO `_tmp_second_200_master_rollback_splits_20260729`
(`old_mother`,`map_id`,`new_mother`,`max_limit`,`description`)
SELECT DISTINCT `lm`.`old_mother`,`lm`.`map_id`,
       `lm`.`old_mother` +
           CASE `lm`.`map_id`
               WHEN 0 THEN 100000
               WHEN 1 THEN 200000
               WHEN 530 THEN 300000
               WHEN 571 THEN 400000
           END,
       `m`.`max_limit`,`m`.`description`
FROM `_tmp_second_200_master_rollback_maps_20260729` AS `lm`
INNER JOIN `_backup_pool_manifest_second_200_master_20260729` AS `m`
    ON `m`.`old_mother` = `lm`.`old_mother`
WHERE `lm`.`map_id` <> `m`.`canonical_map`
  AND `lm`.`map_id` IN (0,1,530,571);

SET @second_200_master_rollback_backup_ok :=
(
    SELECT
        (SELECT COUNT(*)
         FROM `_backup_pool_manifest_second_200_master_20260729`) = 200
        AND
        (SELECT COUNT(*)
         FROM `_backup_pool_template_second_200_master_20260729`) = 200
        AND
        (SELECT COUNT(*)
         FROM `_backup_pool_pool_second_200_master_20260729`) = 800
        AND
        (SELECT COUNT(*)
         FROM `_tmp_second_200_master_rollback_maps_20260729`) = 800
        AND
        (SELECT COUNT(*)
         FROM `_tmp_second_200_master_rollback_splits_20260729`) = 200
);

SET @second_200_master_rollback_links_ok :=
(
    SELECT COUNT(*) = 800
       AND SUM(
           `pp`.`mother_pool` = `b`.`mother_pool`
           OR `pp`.`mother_pool` = `s`.`new_mother`
       ) = 800
       AND SUM(`pp`.`chance` = `b`.`chance`) = 800
       AND SUM(`pp`.`description` <=> `b`.`description`) = 800
    FROM `_backup_pool_pool_second_200_master_20260729` AS `b`
    INNER JOIN `pool_pool` AS `pp` ON `pp`.`pool_id` = `b`.`pool_id`
    INNER JOIN `_tmp_second_200_master_rollback_maps_20260729` AS `lm`
        ON `lm`.`old_mother` = `b`.`mother_pool`
       AND `lm`.`child_pool` = `b`.`pool_id`
    LEFT JOIN `_tmp_second_200_master_rollback_splits_20260729` AS `s`
        ON `s`.`old_mother` = `b`.`mother_pool`
       AND `s`.`map_id` = `lm`.`map_id`
);

SET @second_200_master_rollback_no_foreign_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_pool` AS `pp`
    INNER JOIN `_tmp_second_200_master_rollback_splits_20260729` AS `s`
        ON `s`.`new_mother` = `pp`.`mother_pool`
        OR `s`.`new_mother` = `pp`.`pool_id`
    LEFT JOIN `_backup_pool_pool_second_200_master_20260729` AS `b`
        ON `b`.`pool_id` = `pp`.`pool_id`
    WHERE `b`.`pool_id` IS NULL
       OR `s`.`new_mother` = `pp`.`pool_id`
);

SET @second_200_master_rollback_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_second_200_master_rollback_splits_20260729` AS `s`
        ON `s`.`new_mother` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> `s`.`max_limit`
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @second_200_master_rollback_ok :=
    @second_200_master_rollback_backup_ok
    AND @second_200_master_rollback_links_ok
    AND @second_200_master_rollback_no_foreign_ok
    AND @second_200_master_rollback_templates_ok;

START TRANSACTION;

UPDATE `pool_pool` AS `pp`
INNER JOIN `_backup_pool_pool_second_200_master_20260729` AS `b`
    ON `b`.`pool_id` = `pp`.`pool_id`
SET `pp`.`mother_pool` = `b`.`mother_pool`,
    `pp`.`chance` = `b`.`chance`,
    `pp`.`description` = `b`.`description`
WHERE @second_200_master_rollback_ok = 1;

DELETE `pt`
FROM `pool_template` AS `pt`
INNER JOIN `_tmp_second_200_master_rollback_splits_20260729` AS `s`
    ON `s`.`new_mother` = `pt`.`entry`
WHERE @second_200_master_rollback_ok = 1
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

SELECT @second_200_master_rollback_ok AS `rollback_guard`,
       (SELECT COUNT(*)
        FROM `_backup_pool_manifest_second_200_master_20260729`)
           AS `manifest_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_template_second_200_master_20260729`)
           AS `template_backup_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_pool_second_200_master_20260729`)
           AS `link_backup_rows`,
       (SELECT COUNT(*)
        FROM `_tmp_second_200_master_rollback_splits_20260729`)
           AS `new_mother_count`;

DROP TEMPORARY TABLE `_tmp_second_200_master_rollback_splits_20260729`;
DROP TEMPORARY TABLE `_tmp_second_200_master_rollback_maps_20260729`;
