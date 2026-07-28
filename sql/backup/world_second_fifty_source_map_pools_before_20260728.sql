-- Exact, idempotent rollback for
-- 2026_07_28_03_world_split_second_fifty_source_map_pools.sql.

DROP TEMPORARY TABLE IF EXISTS `_tmp_second_fifty_map_rollback_20260728`;
CREATE TEMPORARY TABLE `_tmp_second_fifty_map_rollback_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `canonical_map` SMALLINT UNSIGNED NOT NULL,
    `max_limit` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_pool`)
);

INSERT INTO `_tmp_second_fifty_map_rollback_20260728`
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

DROP TEMPORARY TABLE IF EXISTS `_tmp_second_fifty_rollback_splits_20260728`;
CREATE TEMPORARY TABLE `_tmp_second_fifty_rollback_splits_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_pool` MEDIUMINT UNSIGNED NOT NULL,
    `max_limit` INT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_pool`,`map_id`),
    UNIQUE KEY (`new_pool`)
);

INSERT INTO `_tmp_second_fifty_rollback_splits_20260728`
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
INNER JOIN `_tmp_second_fifty_map_rollback_20260728` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
WHERE `g`.`map` <> `m`.`canonical_map`
  AND `g`.`map` IN (0,1,530)
GROUP BY `b`.`pool_entry`,`g`.`map`,`m`.`max_limit`;

SET @second_fifty_rollback_backup_ok :=
(
    SELECT
        (SELECT COUNT(*) FROM `_backup_pool_template_second_fifty_maps_20260728`) = 50
        AND
        (SELECT COUNT(*) FROM `_backup_pool_gameobject_second_fifty_maps_20260728`) = 200
        AND
        (SELECT COUNT(*) FROM `_tmp_second_fifty_rollback_splits_20260728`) = 58
);

SET @second_fifty_rollback_members_ok :=
(
    SELECT COUNT(*) = 200
       AND SUM(
           `pg`.`pool_entry` = `b`.`pool_entry`
           OR `pg`.`pool_entry` = `s`.`new_pool`
       ) = 200
       AND SUM(`pg`.`chance` = `b`.`chance`) = 200
       AND SUM(`pg`.`description` <=> `b`.`description`) = 200
    FROM `_backup_pool_gameobject_second_fifty_maps_20260728` AS `b`
    INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`guid` = `b`.`guid`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    LEFT JOIN `_tmp_second_fifty_rollback_splits_20260728` AS `s`
        ON `s`.`old_pool` = `b`.`pool_entry` AND `s`.`map_id` = `g`.`map`
);

SET @second_fifty_rollback_no_foreign_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_gameobject` AS `pg`
    INNER JOIN `_tmp_second_fifty_rollback_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pg`.`pool_entry`
    LEFT JOIN `_backup_pool_gameobject_second_fifty_maps_20260728` AS `b`
        ON `b`.`guid` = `pg`.`guid`
    WHERE `b`.`guid` IS NULL
);

SET @second_fifty_rollback_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_second_fifty_rollback_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> `s`.`max_limit`
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @second_fifty_rollback_ok :=
    @second_fifty_rollback_backup_ok
    AND @second_fifty_rollback_members_ok
    AND @second_fifty_rollback_no_foreign_ok
    AND @second_fifty_rollback_templates_ok;

START TRANSACTION;

UPDATE `pool_gameobject` AS `pg`
INNER JOIN `_backup_pool_gameobject_second_fifty_maps_20260728` AS `b`
    ON `b`.`guid` = `pg`.`guid`
SET `pg`.`pool_entry` = `b`.`pool_entry`,
    `pg`.`chance` = `b`.`chance`,
    `pg`.`description` = `b`.`description`
WHERE @second_fifty_rollback_ok = 1;

DELETE `pt`
FROM `pool_template` AS `pt`
INNER JOIN `_tmp_second_fifty_rollback_splits_20260728` AS `s`
    ON `s`.`new_pool` = `pt`.`entry`
WHERE @second_fifty_rollback_ok = 1
  AND NOT EXISTS
      (SELECT 1 FROM `pool_gameobject` AS `pg`
       WHERE `pg`.`pool_entry` = `pt`.`entry`)
  AND NOT EXISTS
      (SELECT 1 FROM `pool_pool` AS `pp`
       WHERE `pp`.`pool_id` = `pt`.`entry`
          OR `pp`.`mother_pool` = `pt`.`entry`);

COMMIT;

SELECT @second_fifty_rollback_ok AS `rollback_guard`,
       (SELECT COUNT(*) FROM `_backup_pool_template_second_fifty_maps_20260728`)
           AS `template_backup_rows`,
       (SELECT COUNT(*) FROM `_backup_pool_gameobject_second_fifty_maps_20260728`)
           AS `member_backup_rows`;

DROP TEMPORARY TABLE `_tmp_second_fifty_rollback_splits_20260728`;
DROP TEMPORARY TABLE `_tmp_second_fifty_map_rollback_20260728`;
