-- Exact, idempotent rollback for
-- 2026_07_28_09_world_split_three_times_two_hundred_resource_pools.sql.

DROP TEMPORARY TABLE IF EXISTS `_tmp_three_x_200_rollback_splits_20260728`;
CREATE TEMPORARY TABLE `_tmp_three_x_200_rollback_splits_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_pool` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    `max_limit` MEDIUMINT UNSIGNED NOT NULL,
    `batch_no` TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_pool`,`map_id`),
    UNIQUE KEY (`new_pool`)
);

INSERT INTO `_tmp_three_x_200_rollback_splits_20260728`
(`old_pool`,`map_id`,`new_pool`,`description`,`max_limit`,`batch_no`)
SELECT `b`.`pool_entry`,`g`.`map`,
       `b`.`pool_entry` +
           CASE `g`.`map`
               WHEN 0 THEN 100000
               WHEN 1 THEN 200000
               WHEN 530 THEN 300000
           END,
       MIN(`b`.`description`),`m`.`max_limit`,`m`.`batch_no`
FROM `_backup_pool_gameobject_three_x_200_resources_20260728` AS `b`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
INNER JOIN `_backup_pool_manifest_three_x_200_resources_20260728` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
WHERE `g`.`map` <> `m`.`canonical_map`
  AND `g`.`map` IN (0,1,530)
GROUP BY `b`.`pool_entry`,`g`.`map`,`m`.`max_limit`,`m`.`batch_no`;

SET @three_x_200_rollback_backup_ok :=
(
    SELECT
        (SELECT COUNT(*) FROM `_backup_pool_manifest_three_x_200_resources_20260728`) = 600
        AND
        (SELECT COUNT(*) FROM `_backup_pool_template_three_x_200_resources_20260728`) = 600
        AND
        (SELECT COUNT(*) FROM `_backup_pool_gameobject_three_x_200_resources_20260728`) = 2400
        AND
        (SELECT COUNT(*) FROM `_tmp_three_x_200_rollback_splits_20260728`) = 636
);

SET @three_x_200_rollback_members_ok :=
(
    SELECT COUNT(*) = 2400
       AND SUM(
           `pg`.`pool_entry` = `b`.`pool_entry`
           OR `pg`.`pool_entry` = `s`.`new_pool`
       ) = 2400
       AND SUM(`pg`.`chance` = `b`.`chance`) = 2400
       AND SUM(`pg`.`description` <=> `b`.`description`) = 2400
    FROM `_backup_pool_gameobject_three_x_200_resources_20260728` AS `b`
    INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`guid` = `b`.`guid`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    LEFT JOIN `_tmp_three_x_200_rollback_splits_20260728` AS `s`
        ON `s`.`old_pool` = `b`.`pool_entry` AND `s`.`map_id` = `g`.`map`
);

SET @three_x_200_rollback_no_foreign_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_gameobject` AS `pg`
    INNER JOIN `_tmp_three_x_200_rollback_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pg`.`pool_entry`
    LEFT JOIN `_backup_pool_gameobject_three_x_200_resources_20260728` AS `b`
        ON `b`.`guid` = `pg`.`guid`
    WHERE `b`.`guid` IS NULL
);

SET @three_x_200_rollback_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_three_x_200_rollback_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> `s`.`max_limit`
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @three_x_200_rollback_ok :=
    @three_x_200_rollback_backup_ok
    AND @three_x_200_rollback_members_ok
    AND @three_x_200_rollback_no_foreign_ok
    AND @three_x_200_rollback_templates_ok;

START TRANSACTION;

UPDATE `pool_gameobject` AS `pg`
INNER JOIN `_backup_pool_gameobject_three_x_200_resources_20260728` AS `b`
    ON `b`.`guid` = `pg`.`guid`
SET `pg`.`pool_entry` = `b`.`pool_entry`,
    `pg`.`chance` = `b`.`chance`,
    `pg`.`description` = `b`.`description`
WHERE @three_x_200_rollback_ok = 1;

DELETE `pt`
FROM `pool_template` AS `pt`
INNER JOIN `_tmp_three_x_200_rollback_splits_20260728` AS `s`
    ON `s`.`new_pool` = `pt`.`entry`
WHERE @three_x_200_rollback_ok = 1
  AND NOT EXISTS
      (SELECT 1 FROM `pool_gameobject` AS `pg`
       WHERE `pg`.`pool_entry` = `pt`.`entry`)
  AND NOT EXISTS
      (SELECT 1 FROM `pool_pool` AS `pp`
       WHERE `pp`.`pool_id` = `pt`.`entry`
          OR `pp`.`mother_pool` = `pt`.`entry`);

COMMIT;

SELECT @three_x_200_rollback_ok AS `rollback_guard`,
       (SELECT COUNT(*) FROM `_backup_pool_manifest_three_x_200_resources_20260728`)
           AS `manifest_rows`,
       (SELECT COUNT(*) FROM `_backup_pool_template_three_x_200_resources_20260728`)
           AS `template_backup_rows`,
       (SELECT COUNT(*) FROM `_backup_pool_gameobject_three_x_200_resources_20260728`)
           AS `member_backup_rows`;

SELECT `batch_no`,COUNT(*) AS `new_pool_count`
FROM `_tmp_three_x_200_rollback_splits_20260728`
GROUP BY `batch_no`
ORDER BY `batch_no`;

DROP TEMPORARY TABLE `_tmp_three_x_200_rollback_splits_20260728`;
