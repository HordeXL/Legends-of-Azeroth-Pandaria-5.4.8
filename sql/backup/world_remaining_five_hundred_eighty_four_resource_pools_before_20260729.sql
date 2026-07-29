-- Exact, idempotent rollback for
-- 2026_07_29_00_world_split_remaining_five_hundred_eighty_four_resource_pools.sql.

DROP TEMPORARY TABLE IF EXISTS `_tmp_remaining_584_rollback_splits_20260729`;
CREATE TEMPORARY TABLE `_tmp_remaining_584_rollback_splits_20260729`
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

INSERT INTO `_tmp_remaining_584_rollback_splits_20260729`
(`old_pool`,`map_id`,`new_pool`,`description`,`max_limit`,`batch_no`)
SELECT `b`.`pool_entry`,`g`.`map`,
       `b`.`pool_entry` +
           CASE `g`.`map`
               WHEN 0 THEN 100000
               WHEN 1 THEN 200000
               WHEN 530 THEN 300000
           END,
       MIN(`b`.`description`),`m`.`max_limit`,`m`.`batch_no`
FROM `_backup_pool_gameobject_remaining_584_resources_20260729` AS `b`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
INNER JOIN `_backup_pool_manifest_remaining_584_resources_20260729` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
WHERE `g`.`map` <> `m`.`canonical_map`
  AND `g`.`map` IN (0,1,530)
GROUP BY `b`.`pool_entry`,`g`.`map`,`m`.`max_limit`,`m`.`batch_no`;

SET @remaining_584_rollback_backup_ok :=
(
    SELECT
        (SELECT COUNT(*) FROM `_backup_pool_manifest_remaining_584_resources_20260729`) = 584
        AND
        (SELECT COUNT(*) FROM `_backup_pool_template_remaining_584_resources_20260729`) = 584
        AND
        (SELECT COUNT(*) FROM `_backup_pool_gameobject_remaining_584_resources_20260729`) = 2336
        AND
        (SELECT COUNT(*) FROM `_tmp_remaining_584_rollback_splits_20260729`) = 672
);

SET @remaining_584_rollback_members_ok :=
(
    SELECT COUNT(*) = 2336
       AND SUM(
           `pg`.`pool_entry` = `b`.`pool_entry`
           OR `pg`.`pool_entry` = `s`.`new_pool`
       ) = 2336
       AND SUM(`pg`.`chance` = `b`.`chance`) = 2336
       AND SUM(`pg`.`description` <=> `b`.`description`) = 2336
    FROM `_backup_pool_gameobject_remaining_584_resources_20260729` AS `b`
    INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`guid` = `b`.`guid`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    LEFT JOIN `_tmp_remaining_584_rollback_splits_20260729` AS `s`
        ON `s`.`old_pool` = `b`.`pool_entry` AND `s`.`map_id` = `g`.`map`
);

SET @remaining_584_rollback_no_foreign_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_gameobject` AS `pg`
    INNER JOIN `_tmp_remaining_584_rollback_splits_20260729` AS `s`
        ON `s`.`new_pool` = `pg`.`pool_entry`
    LEFT JOIN `_backup_pool_gameobject_remaining_584_resources_20260729` AS `b`
        ON `b`.`guid` = `pg`.`guid`
    WHERE `b`.`guid` IS NULL
);

SET @remaining_584_rollback_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_remaining_584_rollback_splits_20260729` AS `s`
        ON `s`.`new_pool` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> `s`.`max_limit`
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @remaining_584_rollback_ok :=
    @remaining_584_rollback_backup_ok
    AND @remaining_584_rollback_members_ok
    AND @remaining_584_rollback_no_foreign_ok
    AND @remaining_584_rollback_templates_ok;

START TRANSACTION;

UPDATE `pool_gameobject` AS `pg`
INNER JOIN `_backup_pool_gameobject_remaining_584_resources_20260729` AS `b`
    ON `b`.`guid` = `pg`.`guid`
SET `pg`.`pool_entry` = `b`.`pool_entry`,
    `pg`.`chance` = `b`.`chance`,
    `pg`.`description` = `b`.`description`
WHERE @remaining_584_rollback_ok = 1;

DELETE `pt`
FROM `pool_template` AS `pt`
INNER JOIN `_tmp_remaining_584_rollback_splits_20260729` AS `s`
    ON `s`.`new_pool` = `pt`.`entry`
WHERE @remaining_584_rollback_ok = 1
  AND NOT EXISTS
      (SELECT 1 FROM `pool_gameobject` AS `pg`
       WHERE `pg`.`pool_entry` = `pt`.`entry`)
  AND NOT EXISTS
      (SELECT 1 FROM `pool_pool` AS `pp`
       WHERE `pp`.`pool_id` = `pt`.`entry`
          OR `pp`.`mother_pool` = `pt`.`entry`);

COMMIT;

SELECT @remaining_584_rollback_ok AS `rollback_guard`,
       (SELECT COUNT(*) FROM `_backup_pool_manifest_remaining_584_resources_20260729`)
           AS `manifest_rows`,
       (SELECT COUNT(*) FROM `_backup_pool_template_remaining_584_resources_20260729`)
           AS `template_backup_rows`,
       (SELECT COUNT(*) FROM `_backup_pool_gameobject_remaining_584_resources_20260729`)
           AS `member_backup_rows`;

SELECT `batch_no`,COUNT(*) AS `new_pool_count`
FROM `_tmp_remaining_584_rollback_splits_20260729`
GROUP BY `batch_no`
ORDER BY `batch_no`;

DROP TEMPORARY TABLE `_tmp_remaining_584_rollback_splits_20260729`;
