-- Exact, idempotent rollback for
-- 2026_07_28_04_world_split_third_fifty_resource_pools.sql.

DROP TEMPORARY TABLE IF EXISTS `_tmp_third_fifty_resource_rollback_20260728`;
CREATE TEMPORARY TABLE `_tmp_third_fifty_resource_rollback_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `canonical_map` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_pool`)
);

INSERT INTO `_tmp_third_fifty_resource_rollback_20260728`
(`old_pool`,`canonical_map`) VALUES
(10840,1),(10841,0),(10842,0),(10843,0),(10846,0),
(10847,0),(10848,1),(10849,0),(10851,1),(10852,0),
(10866,530),(10873,0),(10874,0),(10882,530),(10900,530),
(10901,1),(10904,0),(10905,530),(10906,1),(10909,1),
(10910,1),(10912,0),(10913,0),(10914,0),(10915,0),
(10916,1),(10917,0),(10919,0),(10920,0),(10922,0),
(10923,1),(10924,1),(10925,1),(10926,0),(10927,0),
(10928,1),(10929,1),(10930,0),(10931,0),(10932,0),
(10933,0),(10934,0),(10936,0),(10937,0),(10940,1),
(10941,0),(10942,0),(10944,0),(10946,0),(10954,1);

DROP TEMPORARY TABLE IF EXISTS `_tmp_third_fifty_rollback_splits_20260728`;
CREATE TEMPORARY TABLE `_tmp_third_fifty_rollback_splits_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_pool` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_pool`,`map_id`),
    UNIQUE KEY (`new_pool`)
);

INSERT INTO `_tmp_third_fifty_rollback_splits_20260728`
(`old_pool`,`map_id`,`new_pool`,`description`)
SELECT `b`.`pool_entry`,`g`.`map`,
       `b`.`pool_entry` +
           CASE `g`.`map`
               WHEN 0 THEN 100000
               WHEN 1 THEN 200000
               WHEN 530 THEN 300000
           END,
       MIN(`b`.`description`)
FROM `_backup_pool_gameobject_third_fifty_resources_20260728` AS `b`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
INNER JOIN `_tmp_third_fifty_resource_rollback_20260728` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
WHERE `g`.`map` <> `m`.`canonical_map`
  AND `g`.`map` IN (0,1,530)
GROUP BY `b`.`pool_entry`,`g`.`map`;

SET @third_fifty_rollback_backup_ok :=
(
    SELECT
        (SELECT COUNT(*) FROM `_backup_pool_template_third_fifty_resources_20260728`) = 50
        AND
        (SELECT COUNT(*) FROM `_backup_pool_gameobject_third_fifty_resources_20260728`) = 200
        AND
        (SELECT COUNT(*) FROM `_tmp_third_fifty_rollback_splits_20260728`) = 51
);

SET @third_fifty_rollback_members_ok :=
(
    SELECT COUNT(*) = 200
       AND SUM(
           `pg`.`pool_entry` = `b`.`pool_entry`
           OR `pg`.`pool_entry` = `s`.`new_pool`
       ) = 200
       AND SUM(`pg`.`chance` = `b`.`chance`) = 200
       AND SUM(`pg`.`description` <=> `b`.`description`) = 200
    FROM `_backup_pool_gameobject_third_fifty_resources_20260728` AS `b`
    INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`guid` = `b`.`guid`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    LEFT JOIN `_tmp_third_fifty_rollback_splits_20260728` AS `s`
        ON `s`.`old_pool` = `b`.`pool_entry` AND `s`.`map_id` = `g`.`map`
);

SET @third_fifty_rollback_no_foreign_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_gameobject` AS `pg`
    INNER JOIN `_tmp_third_fifty_rollback_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pg`.`pool_entry`
    LEFT JOIN `_backup_pool_gameobject_third_fifty_resources_20260728` AS `b`
        ON `b`.`guid` = `pg`.`guid`
    WHERE `b`.`guid` IS NULL
);

SET @third_fifty_rollback_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_third_fifty_rollback_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> 2
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @third_fifty_rollback_ok :=
    @third_fifty_rollback_backup_ok
    AND @third_fifty_rollback_members_ok
    AND @third_fifty_rollback_no_foreign_ok
    AND @third_fifty_rollback_templates_ok;

START TRANSACTION;

UPDATE `pool_gameobject` AS `pg`
INNER JOIN `_backup_pool_gameobject_third_fifty_resources_20260728` AS `b`
    ON `b`.`guid` = `pg`.`guid`
SET `pg`.`pool_entry` = `b`.`pool_entry`,
    `pg`.`chance` = `b`.`chance`,
    `pg`.`description` = `b`.`description`
WHERE @third_fifty_rollback_ok = 1;

DELETE `pt`
FROM `pool_template` AS `pt`
INNER JOIN `_tmp_third_fifty_rollback_splits_20260728` AS `s`
    ON `s`.`new_pool` = `pt`.`entry`
WHERE @third_fifty_rollback_ok = 1
  AND NOT EXISTS
      (SELECT 1 FROM `pool_gameobject` AS `pg`
       WHERE `pg`.`pool_entry` = `pt`.`entry`)
  AND NOT EXISTS
      (SELECT 1 FROM `pool_pool` AS `pp`
       WHERE `pp`.`pool_id` = `pt`.`entry`
          OR `pp`.`mother_pool` = `pt`.`entry`);

COMMIT;

SELECT @third_fifty_rollback_ok AS `rollback_guard`,
       (SELECT COUNT(*) FROM `_backup_pool_template_third_fifty_resources_20260728`)
           AS `template_backup_rows`,
       (SELECT COUNT(*) FROM `_backup_pool_gameobject_third_fifty_resources_20260728`)
           AS `member_backup_rows`;

DROP TEMPORARY TABLE `_tmp_third_fifty_rollback_splits_20260728`;
DROP TEMPORARY TABLE `_tmp_third_fifty_resource_rollback_20260728`;
