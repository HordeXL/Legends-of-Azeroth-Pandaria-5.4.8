-- Exact, idempotent rollback for
-- 2026_07_28_05_world_split_fourth_fifty_resource_pools.sql.

DROP TEMPORARY TABLE IF EXISTS `_tmp_fourth_fifty_resource_rollback_20260728`;
CREATE TEMPORARY TABLE `_tmp_fourth_fifty_resource_rollback_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `canonical_map` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_pool`)
);

INSERT INTO `_tmp_fourth_fifty_resource_rollback_20260728`
(`old_pool`,`canonical_map`) VALUES
(10960,530),(10977,1),(10978,530),(10979,0),(10981,0),
(10997,530),(10998,1),(11001,0),(11003,1),(11004,1),
(11005,1),(11006,0),(11007,0),(11009,0),(11011,0),
(11012,0),(11015,0),(11017,1),(11018,1),(11019,0),
(11021,0),(11023,0),(11026,0),(11027,1),(11029,1),
(11030,1),(11033,1),(11034,1),(11035,1),(11036,1),
(11038,0),(11039,0),(11040,0),(11048,1),(11062,0),
(11070,1),(11071,1),(11072,0),(11073,0),(11091,530),
(11092,1),(11095,0),(11097,0),(11098,1),(11099,1),
(11100,1),(11101,0),(11102,0),(11103,0),(11104,0);

DROP TEMPORARY TABLE IF EXISTS `_tmp_fourth_fifty_rollback_splits_20260728`;
CREATE TEMPORARY TABLE `_tmp_fourth_fifty_rollback_splits_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_pool` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_pool`,`map_id`),
    UNIQUE KEY (`new_pool`)
);

INSERT INTO `_tmp_fourth_fifty_rollback_splits_20260728`
(`old_pool`,`map_id`,`new_pool`,`description`)
SELECT `b`.`pool_entry`,`g`.`map`,
       `b`.`pool_entry` +
           CASE `g`.`map`
               WHEN 0 THEN 100000
               WHEN 1 THEN 200000
               WHEN 530 THEN 300000
           END,
       MIN(`b`.`description`)
FROM `_backup_pool_gameobject_fourth_fifty_resources_20260728` AS `b`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
INNER JOIN `_tmp_fourth_fifty_resource_rollback_20260728` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
WHERE `g`.`map` <> `m`.`canonical_map`
  AND `g`.`map` IN (0,1,530)
GROUP BY `b`.`pool_entry`,`g`.`map`;

SET @fourth_fifty_rollback_backup_ok :=
(
    SELECT
        (SELECT COUNT(*) FROM `_backup_pool_template_fourth_fifty_resources_20260728`) = 50
        AND
        (SELECT COUNT(*) FROM `_backup_pool_gameobject_fourth_fifty_resources_20260728`) = 200
        AND
        (SELECT COUNT(*) FROM `_tmp_fourth_fifty_rollback_splits_20260728`) = 55
);

SET @fourth_fifty_rollback_members_ok :=
(
    SELECT COUNT(*) = 200
       AND SUM(
           `pg`.`pool_entry` = `b`.`pool_entry`
           OR `pg`.`pool_entry` = `s`.`new_pool`
       ) = 200
       AND SUM(`pg`.`chance` = `b`.`chance`) = 200
       AND SUM(`pg`.`description` <=> `b`.`description`) = 200
    FROM `_backup_pool_gameobject_fourth_fifty_resources_20260728` AS `b`
    INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`guid` = `b`.`guid`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    LEFT JOIN `_tmp_fourth_fifty_rollback_splits_20260728` AS `s`
        ON `s`.`old_pool` = `b`.`pool_entry` AND `s`.`map_id` = `g`.`map`
);

SET @fourth_fifty_rollback_no_foreign_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_gameobject` AS `pg`
    INNER JOIN `_tmp_fourth_fifty_rollback_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pg`.`pool_entry`
    LEFT JOIN `_backup_pool_gameobject_fourth_fifty_resources_20260728` AS `b`
        ON `b`.`guid` = `pg`.`guid`
    WHERE `b`.`guid` IS NULL
);

SET @fourth_fifty_rollback_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_fourth_fifty_rollback_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> 2
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @fourth_fifty_rollback_ok :=
    @fourth_fifty_rollback_backup_ok
    AND @fourth_fifty_rollback_members_ok
    AND @fourth_fifty_rollback_no_foreign_ok
    AND @fourth_fifty_rollback_templates_ok;

START TRANSACTION;

UPDATE `pool_gameobject` AS `pg`
INNER JOIN `_backup_pool_gameobject_fourth_fifty_resources_20260728` AS `b`
    ON `b`.`guid` = `pg`.`guid`
SET `pg`.`pool_entry` = `b`.`pool_entry`,
    `pg`.`chance` = `b`.`chance`,
    `pg`.`description` = `b`.`description`
WHERE @fourth_fifty_rollback_ok = 1;

DELETE `pt`
FROM `pool_template` AS `pt`
INNER JOIN `_tmp_fourth_fifty_rollback_splits_20260728` AS `s`
    ON `s`.`new_pool` = `pt`.`entry`
WHERE @fourth_fifty_rollback_ok = 1
  AND NOT EXISTS
      (SELECT 1 FROM `pool_gameobject` AS `pg`
       WHERE `pg`.`pool_entry` = `pt`.`entry`)
  AND NOT EXISTS
      (SELECT 1 FROM `pool_pool` AS `pp`
       WHERE `pp`.`pool_id` = `pt`.`entry`
          OR `pp`.`mother_pool` = `pt`.`entry`);

COMMIT;

SELECT @fourth_fifty_rollback_ok AS `rollback_guard`,
       (SELECT COUNT(*) FROM `_backup_pool_template_fourth_fifty_resources_20260728`)
           AS `template_backup_rows`,
       (SELECT COUNT(*) FROM `_backup_pool_gameobject_fourth_fifty_resources_20260728`)
           AS `member_backup_rows`;

DROP TEMPORARY TABLE `_tmp_fourth_fifty_rollback_splits_20260728`;
DROP TEMPORARY TABLE `_tmp_fourth_fifty_resource_rollback_20260728`;
