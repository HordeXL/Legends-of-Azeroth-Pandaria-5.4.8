-- Split the second 50 source-described pools merged across maps 0, 1 and 530.
-- The package contains two Copper Vein pools, 15 Tattered Chest pools and
-- 33 herb/resource pools. All 200 original members are preserved.

DROP TEMPORARY TABLE IF EXISTS `_tmp_second_fifty_map_pools_20260728`;
CREATE TEMPORARY TABLE `_tmp_second_fifty_map_pools_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `canonical_map` SMALLINT UNSIGNED NOT NULL,
    `max_limit` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_pool`)
);

INSERT INTO `_tmp_second_fifty_map_pools_20260728`
(`old_pool`,`canonical_map`,`max_limit`) VALUES
(5878,0,2),(6038,1,2),
(10746,1,1),(10747,0,1),(10749,1,1),(10750,0,1),(10751,530,1),
(10752,1,1),(10753,0,1),(10754,0,1),(10755,1,1),(10756,530,1),
(10758,530,1),(10759,530,1),(10760,1,1),(10761,1,1),(10762,1,1),
(10763,1,2),(10770,1,2),(10778,1,2),(10787,530,2),(10788,0,2),
(10790,0,2),(10806,0,2),(10811,1,2),(10812,1,2),(10813,0,2),
(10814,1,2),(10815,0,2),(10817,1,2),(10818,0,2),(10819,0,2),
(10820,0,2),(10821,0,2),(10822,0,2),(10823,1,2),(10824,1,2),
(10825,0,2),(10826,1,2),(10827,1,2),(10828,0,2),(10830,1,2),
(10831,1,2),(10832,0,2),(10833,1,2),(10834,0,2),(10835,1,2),
(10836,0,2),(10837,1,2),(10838,0,2);

CREATE TABLE IF NOT EXISTS `_backup_pool_template_second_fifty_maps_20260728`
LIKE `pool_template`;

INSERT INTO `_backup_pool_template_second_fifty_maps_20260728`
SELECT `pt`.*
FROM `pool_template` AS `pt`
INNER JOIN `_tmp_second_fifty_map_pools_20260728` AS `m`
    ON `m`.`old_pool` = `pt`.`entry`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_template_second_fifty_maps_20260728` AS `b`
    WHERE `b`.`entry` = `pt`.`entry`
);

CREATE TABLE IF NOT EXISTS `_backup_pool_gameobject_second_fifty_maps_20260728`
LIKE `pool_gameobject`;

INSERT INTO `_backup_pool_gameobject_second_fifty_maps_20260728`
SELECT `pg`.*
FROM `pool_gameobject` AS `pg`
INNER JOIN `_tmp_second_fifty_map_pools_20260728` AS `m`
    ON `m`.`old_pool` = `pg`.`pool_entry`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_gameobject_second_fifty_maps_20260728` AS `b`
    WHERE `b`.`guid` = `pg`.`guid`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_second_fifty_map_splits_20260728`;
CREATE TEMPORARY TABLE `_tmp_second_fifty_map_splits_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_pool` MEDIUMINT UNSIGNED NOT NULL,
    `max_limit` INT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_pool`,`map_id`),
    UNIQUE KEY (`new_pool`)
);

INSERT INTO `_tmp_second_fifty_map_splits_20260728`
(`old_pool`,`map_id`,`new_pool`,`max_limit`,`description`)
SELECT `b`.`pool_entry`,`g`.`map`,
       `b`.`pool_entry` +
           CASE `g`.`map`
               WHEN 0 THEN 100000
               WHEN 1 THEN 200000
               WHEN 530 THEN 300000
           END,
       `m`.`max_limit`,MIN(`b`.`description`)
FROM `_backup_pool_gameobject_second_fifty_maps_20260728` AS `b`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
INNER JOIN `_tmp_second_fifty_map_pools_20260728` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
WHERE `g`.`map` <> `m`.`canonical_map`
  AND `g`.`map` IN (0,1,530)
GROUP BY `b`.`pool_entry`,`g`.`map`,`m`.`max_limit`;

SET @second_fifty_manifest_ok :=
(
    SELECT COUNT(*) = 50
    FROM `_tmp_second_fifty_map_pools_20260728`
);

SET @second_fifty_template_backup_ok :=
(
    SELECT COUNT(*) = 50
       AND SUM(`b`.`max_limit` = `m`.`max_limit`) = 50
       AND SUM(
           CAST(SUBSTRING_INDEX(`b`.`description`,'map=',-1) AS UNSIGNED)
           = `m`.`canonical_map`
       ) = 50
    FROM `_backup_pool_template_second_fifty_maps_20260728` AS `b`
    INNER JOIN `_tmp_second_fifty_map_pools_20260728` AS `m`
        ON `m`.`old_pool` = `b`.`entry`
);

SET @second_fifty_member_backup_ok :=
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
    FROM `_backup_pool_gameobject_second_fifty_maps_20260728` AS `b`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    INNER JOIN `_backup_pool_template_second_fifty_maps_20260728` AS `pt`
        ON `pt`.`entry` = `b`.`pool_entry`
    INNER JOIN `_tmp_second_fifty_map_pools_20260728` AS `m`
        ON `m`.`old_pool` = `b`.`pool_entry`
);

SET @second_fifty_four_members_ok :=
(
    SELECT COUNT(*) = 50
       AND MIN(`x`.`member_count`) = 4
       AND MAX(`x`.`member_count`) = 4
    FROM
    (
        SELECT `b`.`pool_entry`,COUNT(*) AS `member_count`
        FROM `_backup_pool_gameobject_second_fifty_maps_20260728` AS `b`
        INNER JOIN `_tmp_second_fifty_map_pools_20260728` AS `m`
            ON `m`.`old_pool` = `b`.`pool_entry`
        GROUP BY `b`.`pool_entry`
    ) AS `x`
);

SET @second_fifty_split_ok :=
(
    SELECT COUNT(*) = 58
    FROM `_tmp_second_fifty_map_splits_20260728`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_second_fifty_all_pool_ids_20260728`;
CREATE TEMPORARY TABLE `_tmp_second_fifty_all_pool_ids_20260728`
(
    `pool_id` MEDIUMINT UNSIGNED NOT NULL,
    PRIMARY KEY (`pool_id`)
);

INSERT INTO `_tmp_second_fifty_all_pool_ids_20260728` (`pool_id`)
SELECT `old_pool` FROM `_tmp_second_fifty_map_pools_20260728`;

INSERT INTO `_tmp_second_fifty_all_pool_ids_20260728` (`pool_id`)
SELECT `new_pool` FROM `_tmp_second_fifty_map_splits_20260728`;

SET @second_fifty_no_hierarchy_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_pool` AS `pp`
    INNER JOIN `_tmp_second_fifty_all_pool_ids_20260728` AS `p`
        ON `p`.`pool_id` = `pp`.`pool_id`
        OR `p`.`pool_id` = `pp`.`mother_pool`
);

SET @second_fifty_target_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_second_fifty_map_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> `s`.`max_limit`
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @second_fifty_original_state_ok :=
(
    SELECT COUNT(*) = 200
       AND SUM(`pg`.`pool_entry` = `b`.`pool_entry`) = 200
       AND SUM(`pg`.`chance` = `b`.`chance`) = 200
       AND SUM(`pg`.`description` <=> `b`.`description`) = 200
    FROM `_backup_pool_gameobject_second_fifty_maps_20260728` AS `b`
    INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`guid` = `b`.`guid`
);

SET @second_fifty_final_state_ok :=
(
    SELECT COUNT(*) = 200
       AND SUM(
           `pg`.`pool_entry` =
           CASE WHEN `g`.`map` = `m`.`canonical_map`
                THEN `m`.`old_pool` ELSE `s`.`new_pool` END
       ) = 200
       AND SUM(`pg`.`chance` = `b`.`chance`) = 200
       AND SUM(`pg`.`description` <=> `b`.`description`) = 200
    FROM `_backup_pool_gameobject_second_fifty_maps_20260728` AS `b`
    INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`guid` = `b`.`guid`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    INNER JOIN `_tmp_second_fifty_map_pools_20260728` AS `m`
        ON `m`.`old_pool` = `b`.`pool_entry`
    LEFT JOIN `_tmp_second_fifty_map_splits_20260728` AS `s`
        ON `s`.`old_pool` = `b`.`pool_entry` AND `s`.`map_id` = `g`.`map`
);

SET @second_fifty_no_foreign_members_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_gameobject` AS `pg`
    INNER JOIN `_tmp_second_fifty_map_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pg`.`pool_entry`
    LEFT JOIN `_backup_pool_gameobject_second_fifty_maps_20260728` AS `b`
        ON `b`.`guid` = `pg`.`guid`
    WHERE `b`.`guid` IS NULL
);

SET @second_fifty_apply_ok :=
    @second_fifty_manifest_ok
    AND @second_fifty_template_backup_ok
    AND @second_fifty_member_backup_ok
    AND @second_fifty_four_members_ok
    AND @second_fifty_split_ok
    AND @second_fifty_no_hierarchy_ok
    AND @second_fifty_target_templates_ok
    AND @second_fifty_no_foreign_members_ok
    AND (@second_fifty_original_state_ok OR @second_fifty_final_state_ok);

START TRANSACTION;

INSERT INTO `pool_template` (`entry`,`max_limit`,`description`)
SELECT `s`.`new_pool`,`s`.`max_limit`,`s`.`description`
FROM `_tmp_second_fifty_map_splits_20260728` AS `s`
WHERE @second_fifty_apply_ok = 1
  AND NOT EXISTS
  (
      SELECT 1 FROM `pool_template` AS `pt`
      WHERE `pt`.`entry` = `s`.`new_pool`
  );

UPDATE `pool_gameobject` AS `pg`
INNER JOIN `_backup_pool_gameobject_second_fifty_maps_20260728` AS `b`
    ON `b`.`guid` = `pg`.`guid`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
INNER JOIN `_tmp_second_fifty_map_pools_20260728` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
INNER JOIN `_tmp_second_fifty_map_splits_20260728` AS `s`
    ON `s`.`old_pool` = `b`.`pool_entry` AND `s`.`map_id` = `g`.`map`
SET `pg`.`pool_entry` = `s`.`new_pool`
WHERE @second_fifty_apply_ok = 1
  AND `g`.`map` <> `m`.`canonical_map`;

COMMIT;

SELECT @second_fifty_apply_ok AS `apply_guard`,
       (SELECT COUNT(*) FROM `_backup_pool_template_second_fifty_maps_20260728`)
           AS `template_backup_rows`,
       (SELECT COUNT(*) FROM `_backup_pool_gameobject_second_fifty_maps_20260728`)
           AS `member_backup_rows`,
       (SELECT COUNT(*) FROM `_tmp_second_fifty_map_splits_20260728`)
           AS `new_pool_count`;

DROP TEMPORARY TABLE `_tmp_second_fifty_all_pool_ids_20260728`;
DROP TEMPORARY TABLE `_tmp_second_fifty_map_splits_20260728`;
DROP TEMPORARY TABLE `_tmp_second_fifty_map_pools_20260728`;
