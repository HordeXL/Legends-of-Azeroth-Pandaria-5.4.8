-- Split the fifth 50 source-described cross-map pools.
-- All are GO 2045 herb/resource-family pools with max_limit 2.
-- All 200 members are preserved; no spawn or membership is deleted.

DROP TEMPORARY TABLE IF EXISTS `_tmp_fifth_fifty_resource_pools_20260728`;
CREATE TEMPORARY TABLE `_tmp_fifth_fifty_resource_pools_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `canonical_map` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_pool`)
);

INSERT INTO `_tmp_fifth_fifty_resource_pools_20260728`
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

CREATE TABLE IF NOT EXISTS `_backup_pool_template_fifth_fifty_resources_20260728`
LIKE `pool_template`;

INSERT INTO `_backup_pool_template_fifth_fifty_resources_20260728`
SELECT `pt`.*
FROM `pool_template` AS `pt`
INNER JOIN `_tmp_fifth_fifty_resource_pools_20260728` AS `m`
    ON `m`.`old_pool` = `pt`.`entry`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_template_fifth_fifty_resources_20260728` AS `b`
    WHERE `b`.`entry` = `pt`.`entry`
);

CREATE TABLE IF NOT EXISTS `_backup_pool_gameobject_fifth_fifty_resources_20260728`
LIKE `pool_gameobject`;

INSERT INTO `_backup_pool_gameobject_fifth_fifty_resources_20260728`
SELECT `pg`.*
FROM `pool_gameobject` AS `pg`
INNER JOIN `_tmp_fifth_fifty_resource_pools_20260728` AS `m`
    ON `m`.`old_pool` = `pg`.`pool_entry`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_gameobject_fifth_fifty_resources_20260728` AS `b`
    WHERE `b`.`guid` = `pg`.`guid`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_fifth_fifty_resource_splits_20260728`;
CREATE TEMPORARY TABLE `_tmp_fifth_fifty_resource_splits_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_pool` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_pool`,`map_id`),
    UNIQUE KEY (`new_pool`)
);

INSERT INTO `_tmp_fifth_fifty_resource_splits_20260728`
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
INNER JOIN `_tmp_fifth_fifty_resource_pools_20260728` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
WHERE `g`.`map` <> `m`.`canonical_map`
  AND `g`.`map` IN (0,1,530)
GROUP BY `b`.`pool_entry`,`g`.`map`;

SET @fifth_fifty_manifest_ok :=
(
    SELECT COUNT(*) = 50
    FROM `_tmp_fifth_fifty_resource_pools_20260728`
);

SET @fifth_fifty_template_backup_ok :=
(
    SELECT COUNT(*) = 50
       AND SUM(`b`.`max_limit` = 2) = 50
       AND SUM(
           CAST(SUBSTRING_INDEX(`b`.`description`,'map=',-1) AS UNSIGNED)
           = `m`.`canonical_map`
       ) = 50
    FROM `_backup_pool_template_fifth_fifty_resources_20260728` AS `b`
    INNER JOIN `_tmp_fifth_fifty_resource_pools_20260728` AS `m`
        ON `m`.`old_pool` = `b`.`entry`
);

SET @fifth_fifty_member_backup_ok :=
(
    SELECT COUNT(*) = 200
       AND COUNT(DISTINCT `b`.`pool_entry`) = 50
       AND SUM(
           `b`.`description` =
           CONCAT(
               SUBSTRING_INDEX(`pt`.`description`,'map=',1),
               'map=',`g`.`map`
           )
       ) = 200
       AND SUM(`g`.`map` IN (0,1,530)) = 200
    FROM `_backup_pool_gameobject_fifth_fifty_resources_20260728` AS `b`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    INNER JOIN `_backup_pool_template_fifth_fifty_resources_20260728` AS `pt`
        ON `pt`.`entry` = `b`.`pool_entry`
    INNER JOIN `_tmp_fifth_fifty_resource_pools_20260728` AS `m`
        ON `m`.`old_pool` = `b`.`pool_entry`
);

SET @fifth_fifty_four_members_ok :=
(
    SELECT COUNT(*) = 50
       AND MIN(`x`.`member_count`) = 4
       AND MAX(`x`.`member_count`) = 4
    FROM
    (
        SELECT `b`.`pool_entry`,COUNT(*) AS `member_count`
        FROM `_backup_pool_gameobject_fifth_fifty_resources_20260728` AS `b`
        INNER JOIN `_tmp_fifth_fifty_resource_pools_20260728` AS `m`
            ON `m`.`old_pool` = `b`.`pool_entry`
        GROUP BY `b`.`pool_entry`
    ) AS `x`
);

SET @fifth_fifty_split_ok :=
(
    SELECT COUNT(*) = 52
    FROM `_tmp_fifth_fifty_resource_splits_20260728`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_fifth_fifty_all_pool_ids_20260728`;
CREATE TEMPORARY TABLE `_tmp_fifth_fifty_all_pool_ids_20260728`
(
    `pool_id` MEDIUMINT UNSIGNED NOT NULL,
    PRIMARY KEY (`pool_id`)
);

INSERT INTO `_tmp_fifth_fifty_all_pool_ids_20260728` (`pool_id`)
SELECT `old_pool` FROM `_tmp_fifth_fifty_resource_pools_20260728`;

INSERT INTO `_tmp_fifth_fifty_all_pool_ids_20260728` (`pool_id`)
SELECT `new_pool` FROM `_tmp_fifth_fifty_resource_splits_20260728`;

SET @fifth_fifty_no_hierarchy_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_pool` AS `pp`
    INNER JOIN `_tmp_fifth_fifty_all_pool_ids_20260728` AS `p`
        ON `p`.`pool_id` = `pp`.`pool_id`
        OR `p`.`pool_id` = `pp`.`mother_pool`
);

SET @fifth_fifty_target_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_fifth_fifty_resource_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> 2
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @fifth_fifty_original_state_ok :=
(
    SELECT COUNT(*) = 200
       AND SUM(`pg`.`pool_entry` = `b`.`pool_entry`) = 200
       AND SUM(`pg`.`chance` = `b`.`chance`) = 200
       AND SUM(`pg`.`description` <=> `b`.`description`) = 200
    FROM `_backup_pool_gameobject_fifth_fifty_resources_20260728` AS `b`
    INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`guid` = `b`.`guid`
);

SET @fifth_fifty_final_state_ok :=
(
    SELECT COUNT(*) = 200
       AND SUM(
           `pg`.`pool_entry` =
           CASE WHEN `g`.`map` = `m`.`canonical_map`
                THEN `m`.`old_pool` ELSE `s`.`new_pool` END
       ) = 200
       AND SUM(`pg`.`chance` = `b`.`chance`) = 200
       AND SUM(`pg`.`description` <=> `b`.`description`) = 200
    FROM `_backup_pool_gameobject_fifth_fifty_resources_20260728` AS `b`
    INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`guid` = `b`.`guid`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    INNER JOIN `_tmp_fifth_fifty_resource_pools_20260728` AS `m`
        ON `m`.`old_pool` = `b`.`pool_entry`
    LEFT JOIN `_tmp_fifth_fifty_resource_splits_20260728` AS `s`
        ON `s`.`old_pool` = `b`.`pool_entry` AND `s`.`map_id` = `g`.`map`
);

SET @fifth_fifty_no_foreign_members_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_gameobject` AS `pg`
    INNER JOIN `_tmp_fifth_fifty_resource_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pg`.`pool_entry`
    LEFT JOIN `_backup_pool_gameobject_fifth_fifty_resources_20260728` AS `b`
        ON `b`.`guid` = `pg`.`guid`
    WHERE `b`.`guid` IS NULL
);

SET @fifth_fifty_apply_ok :=
    @fifth_fifty_manifest_ok
    AND @fifth_fifty_template_backup_ok
    AND @fifth_fifty_member_backup_ok
    AND @fifth_fifty_four_members_ok
    AND @fifth_fifty_split_ok
    AND @fifth_fifty_no_hierarchy_ok
    AND @fifth_fifty_target_templates_ok
    AND @fifth_fifty_no_foreign_members_ok
    AND (@fifth_fifty_original_state_ok OR @fifth_fifty_final_state_ok);

START TRANSACTION;

INSERT INTO `pool_template` (`entry`,`max_limit`,`description`)
SELECT `s`.`new_pool`,2,`s`.`description`
FROM `_tmp_fifth_fifty_resource_splits_20260728` AS `s`
WHERE @fifth_fifty_apply_ok = 1
  AND NOT EXISTS
      (SELECT 1 FROM `pool_template` AS `pt`
       WHERE `pt`.`entry` = `s`.`new_pool`);

UPDATE `pool_gameobject` AS `pg`
INNER JOIN `_backup_pool_gameobject_fifth_fifty_resources_20260728` AS `b`
    ON `b`.`guid` = `pg`.`guid`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
INNER JOIN `_tmp_fifth_fifty_resource_pools_20260728` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
INNER JOIN `_tmp_fifth_fifty_resource_splits_20260728` AS `s`
    ON `s`.`old_pool` = `b`.`pool_entry` AND `s`.`map_id` = `g`.`map`
SET `pg`.`pool_entry` = `s`.`new_pool`
WHERE @fifth_fifty_apply_ok = 1
  AND `g`.`map` <> `m`.`canonical_map`;

COMMIT;

SELECT @fifth_fifty_apply_ok AS `apply_guard`,
       (SELECT COUNT(*) FROM `_backup_pool_template_fifth_fifty_resources_20260728`)
           AS `template_backup_rows`,
       (SELECT COUNT(*) FROM `_backup_pool_gameobject_fifth_fifty_resources_20260728`)
           AS `member_backup_rows`,
       (SELECT COUNT(*) FROM `_tmp_fifth_fifty_resource_splits_20260728`)
           AS `new_pool_count`;

DROP TEMPORARY TABLE `_tmp_fifth_fifty_all_pool_ids_20260728`;
DROP TEMPORARY TABLE `_tmp_fifth_fifty_resource_splits_20260728`;
DROP TEMPORARY TABLE `_tmp_fifth_fifty_resource_pools_20260728`;
