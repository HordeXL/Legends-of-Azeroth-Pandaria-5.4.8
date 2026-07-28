-- Exact, idempotent rollback for
-- 2026_07_28_06_world_split_fifth_fifty_resource_pools.sql.

DROP TEMPORARY TABLE IF EXISTS `_tmp_fifth_fifty_resource_rollback_20260728`;
CREATE TEMPORARY TABLE `_tmp_fifth_fifty_resource_rollback_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `canonical_map` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_pool`)
);

INSERT INTO `_tmp_fifth_fifty_resource_rollback_20260728`
(`old_pool`,`canonical_map`) VALUES
(11105,0),(11106,1),(11107,0),(11109,0),(11111,0),
(11112,1),(11114,0),(11115,1),(11116,0),(11117,1),
(11120,1),(11121,0),(11122,0),(11123,0),(11124,1),
(11125,1),(11126,0),(11127,0),(11128,1),(11134,0),
(11136,1),(11137,1),(11158,0),(11166,1),(11167,0),
(11169,530),(11170,0),(11187,530),(11188,1),(11192,1),
(11193,0),(11195,1),(11197,1),(11198,0),(11200,0),
(11201,1),(11202,1),(11203,0),(11204,1),(11206,1),
(11207,0),(11208,1),(11209,0),(11210,0),(11211,0),
(11212,0),(11216,0),(11217,0),(11218,1),(11219,0);

DROP TEMPORARY TABLE IF EXISTS `_tmp_fifth_fifty_rollback_splits_20260728`;
CREATE TEMPORARY TABLE `_tmp_fifth_fifty_rollback_splits_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_pool` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_pool`,`map_id`),
    UNIQUE KEY (`new_pool`)
);

INSERT INTO `_tmp_fifth_fifty_rollback_splits_20260728`
(`old_pool`,`map_id`,`new_pool`,`description`)
SELECT `b`.`pool_entry`,`g`.`map`,
       `b`.`pool_entry` +
           CASE `g`.`map`
               WHEN 0 THEN 100000
               WHEN 1 THEN 200000
               WHEN 530 THEN 300000
           END,
       MIN(`b`.`description`)
FROM `_backup_pool_gameobject_fifth_fifty_resources_20260728` AS `b`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
INNER JOIN `_tmp_fifth_fifty_resource_rollback_20260728` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
WHERE `g`.`map` <> `m`.`canonical_map`
  AND `g`.`map` IN (0,1,530)
GROUP BY `b`.`pool_entry`,`g`.`map`;

SET @fifth_fifty_rollback_backup_ok :=
(
    SELECT
        (SELECT COUNT(*) FROM `_backup_pool_template_fifth_fifty_resources_20260728`) = 50
        AND
        (SELECT COUNT(*) FROM `_backup_pool_gameobject_fifth_fifty_resources_20260728`) = 200
        AND
        (SELECT COUNT(*) FROM `_tmp_fifth_fifty_rollback_splits_20260728`) = 52
);

SET @fifth_fifty_rollback_members_ok :=
(
    SELECT COUNT(*) = 200
       AND SUM(
           `pg`.`pool_entry` = `b`.`pool_entry`
           OR `pg`.`pool_entry` = `s`.`new_pool`
       ) = 200
       AND SUM(`pg`.`chance` = `b`.`chance`) = 200
       AND SUM(`pg`.`description` <=> `b`.`description`) = 200
    FROM `_backup_pool_gameobject_fifth_fifty_resources_20260728` AS `b`
    INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`guid` = `b`.`guid`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    LEFT JOIN `_tmp_fifth_fifty_rollback_splits_20260728` AS `s`
        ON `s`.`old_pool` = `b`.`pool_entry` AND `s`.`map_id` = `g`.`map`
);

SET @fifth_fifty_rollback_no_foreign_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_gameobject` AS `pg`
    INNER JOIN `_tmp_fifth_fifty_rollback_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pg`.`pool_entry`
    LEFT JOIN `_backup_pool_gameobject_fifth_fifty_resources_20260728` AS `b`
        ON `b`.`guid` = `pg`.`guid`
    WHERE `b`.`guid` IS NULL
);

SET @fifth_fifty_rollback_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_fifth_fifty_rollback_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> 2
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @fifth_fifty_rollback_ok :=
    @fifth_fifty_rollback_backup_ok
    AND @fifth_fifty_rollback_members_ok
    AND @fifth_fifty_rollback_no_foreign_ok
    AND @fifth_fifty_rollback_templates_ok;

START TRANSACTION;

UPDATE `pool_gameobject` AS `pg`
INNER JOIN `_backup_pool_gameobject_fifth_fifty_resources_20260728` AS `b`
    ON `b`.`guid` = `pg`.`guid`
SET `pg`.`pool_entry` = `b`.`pool_entry`,
    `pg`.`chance` = `b`.`chance`,
    `pg`.`description` = `b`.`description`
WHERE @fifth_fifty_rollback_ok = 1;

DELETE `pt`
FROM `pool_template` AS `pt`
INNER JOIN `_tmp_fifth_fifty_rollback_splits_20260728` AS `s`
    ON `s`.`new_pool` = `pt`.`entry`
WHERE @fifth_fifty_rollback_ok = 1
  AND NOT EXISTS
      (SELECT 1 FROM `pool_gameobject` AS `pg`
       WHERE `pg`.`pool_entry` = `pt`.`entry`)
  AND NOT EXISTS
      (SELECT 1 FROM `pool_pool` AS `pp`
       WHERE `pp`.`pool_id` = `pt`.`entry`
          OR `pp`.`mother_pool` = `pt`.`entry`);

COMMIT;

SELECT @fifth_fifty_rollback_ok AS `rollback_guard`,
       (SELECT COUNT(*) FROM `_backup_pool_template_fifth_fifty_resources_20260728`)
           AS `template_backup_rows`,
       (SELECT COUNT(*) FROM `_backup_pool_gameobject_fifth_fifty_resources_20260728`)
           AS `member_backup_rows`;

DROP TEMPORARY TABLE `_tmp_fifth_fifty_rollback_splits_20260728`;
DROP TEMPORARY TABLE `_tmp_fifth_fifty_resource_rollback_20260728`;
