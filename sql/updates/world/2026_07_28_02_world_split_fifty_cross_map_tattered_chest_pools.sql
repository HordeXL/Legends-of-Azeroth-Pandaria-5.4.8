-- Split exactly 50 source-described Tattered Chest pools that were merged
-- across maps 0, 1 and 530 under the same pool_entry.
--
-- Every affected pool_gameobject description contains its intended map and
-- matches the current GameObject spawn map. All 200 member rows and all 50
-- original templates are backed up. No GameObject or pool member is deleted.

DROP TEMPORARY TABLE IF EXISTS `_tmp_fifty_tattered_chest_pools_20260728`;
CREATE TEMPORARY TABLE `_tmp_fifty_tattered_chest_pools_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `canonical_map` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_pool`)
);

INSERT INTO `_tmp_fifty_tattered_chest_pools_20260728`
(`old_pool`,`canonical_map`) VALUES
(10686,1),(10687,0),(10688,1),(10689,530),(10690,0),
(10691,1),(10692,1),(10693,530),(10694,0),(10695,0),
(10696,1),(10697,1),(10698,0),(10699,0),(10700,530),
(10701,1),(10702,0),(10705,1),(10709,530),(10710,1),
(10711,0),(10712,0),(10713,1),(10714,530),(10715,1),
(10716,0),(10717,1),(10718,530),(10719,1),(10720,1),
(10721,1),(10722,530),(10724,0),(10726,1),(10727,0),
(10728,0),(10729,530),(10730,530),(10731,1),(10733,1),
(10735,530),(10736,0),(10737,1),(10738,1),(10739,1),
(10740,0),(10741,0),(10742,1),(10743,1),(10745,0);

CREATE TABLE IF NOT EXISTS `_backup_pool_template_fifty_tattered_chests_20260728`
LIKE `pool_template`;

INSERT INTO `_backup_pool_template_fifty_tattered_chests_20260728`
SELECT `pt`.*
FROM `pool_template` AS `pt`
INNER JOIN `_tmp_fifty_tattered_chest_pools_20260728` AS `m`
    ON `m`.`old_pool` = `pt`.`entry`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_template_fifty_tattered_chests_20260728` AS `b`
    WHERE `b`.`entry` = `pt`.`entry`
);

CREATE TABLE IF NOT EXISTS `_backup_pool_gameobject_fifty_tattered_chests_20260728`
LIKE `pool_gameobject`;

INSERT INTO `_backup_pool_gameobject_fifty_tattered_chests_20260728`
SELECT `pg`.*
FROM `pool_gameobject` AS `pg`
INNER JOIN `_tmp_fifty_tattered_chest_pools_20260728` AS `m`
    ON `m`.`old_pool` = `pg`.`pool_entry`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_gameobject_fifty_tattered_chests_20260728` AS `b`
    WHERE `b`.`guid` = `pg`.`guid`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_fifty_tattered_chest_splits_20260728`;
CREATE TEMPORARY TABLE `_tmp_fifty_tattered_chest_splits_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_pool` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_pool`,`map_id`),
    UNIQUE KEY (`new_pool`)
);

INSERT INTO `_tmp_fifty_tattered_chest_splits_20260728`
(`old_pool`,`map_id`,`new_pool`,`description`)
SELECT `b`.`pool_entry`,
       `g`.`map`,
       `b`.`pool_entry` +
           CASE `g`.`map`
               WHEN 0 THEN 100000
               WHEN 1 THEN 200000
               WHEN 530 THEN 300000
           END,
       MIN(`b`.`description`)
FROM `_backup_pool_gameobject_fifty_tattered_chests_20260728` AS `b`
INNER JOIN `gameobject` AS `g`
    ON `g`.`guid` = `b`.`guid`
INNER JOIN `_tmp_fifty_tattered_chest_pools_20260728` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
WHERE `g`.`map` <> `m`.`canonical_map`
  AND `g`.`map` IN (0,1,530)
GROUP BY `b`.`pool_entry`,`g`.`map`;

SET @fifty_tattered_manifest_ok :=
(
    SELECT COUNT(*) = 50
    FROM `_tmp_fifty_tattered_chest_pools_20260728`
);

SET @fifty_tattered_template_backup_ok :=
(
    SELECT COUNT(*) = 50
       AND SUM(`b`.`max_limit` = 1) = 50
       AND SUM(
           `b`.`description` =
           CONCAT('GO 142140,[176589,185881],map=',`m`.`canonical_map`)
       ) = 50
    FROM `_backup_pool_template_fifty_tattered_chests_20260728` AS `b`
    INNER JOIN `_tmp_fifty_tattered_chest_pools_20260728` AS `m`
        ON `m`.`old_pool` = `b`.`entry`
);

SET @fifty_tattered_member_backup_ok :=
(
    SELECT COUNT(*) = 200
       AND COUNT(DISTINCT `b`.`pool_entry`) = 50
       AND SUM(
           `b`.`description` =
           CONCAT('GO 142140,[176589,185881],map=',`g`.`map`)
       ) = 200
       AND SUM(`g`.`map` IN (0,1,530)) = 200
    FROM `_backup_pool_gameobject_fifty_tattered_chests_20260728` AS `b`
    INNER JOIN `gameobject` AS `g`
        ON `g`.`guid` = `b`.`guid`
    INNER JOIN `_tmp_fifty_tattered_chest_pools_20260728` AS `m`
        ON `m`.`old_pool` = `b`.`pool_entry`
);

SET @fifty_tattered_four_members_each_ok :=
(
    SELECT COUNT(*) = 50
       AND MIN(`x`.`member_count`) = 4
       AND MAX(`x`.`member_count`) = 4
    FROM
    (
        SELECT `b`.`pool_entry`,COUNT(*) AS `member_count`
        FROM `_backup_pool_gameobject_fifty_tattered_chests_20260728` AS `b`
        INNER JOIN `_tmp_fifty_tattered_chest_pools_20260728` AS `m`
            ON `m`.`old_pool` = `b`.`pool_entry`
        GROUP BY `b`.`pool_entry`
    ) AS `x`
);

SET @fifty_tattered_split_ok :=
(
    SELECT COUNT(*) = 62
    FROM `_tmp_fifty_tattered_chest_splits_20260728`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_fifty_tattered_chest_all_pool_ids_20260728`;
CREATE TEMPORARY TABLE `_tmp_fifty_tattered_chest_all_pool_ids_20260728`
(
    `pool_id` MEDIUMINT UNSIGNED NOT NULL,
    PRIMARY KEY (`pool_id`)
);

INSERT INTO `_tmp_fifty_tattered_chest_all_pool_ids_20260728` (`pool_id`)
SELECT `old_pool`
FROM `_tmp_fifty_tattered_chest_pools_20260728`;

INSERT INTO `_tmp_fifty_tattered_chest_all_pool_ids_20260728` (`pool_id`)
SELECT `new_pool`
FROM `_tmp_fifty_tattered_chest_splits_20260728`;

SET @fifty_tattered_no_hierarchy_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_pool` AS `pp`
    INNER JOIN `_tmp_fifty_tattered_chest_all_pool_ids_20260728` AS `p`
        ON `p`.`pool_id` = `pp`.`pool_id`
        OR `p`.`pool_id` = `pp`.`mother_pool`
);

SET @fifty_tattered_target_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_fifty_tattered_chest_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> 1
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @fifty_tattered_current_members_ok :=
(
    SELECT COUNT(*) = 200
       AND SUM(
           `pg`.`pool_entry` =
           CASE
               WHEN `g`.`map` = `m`.`canonical_map`
                   THEN `m`.`old_pool`
               ELSE `s`.`new_pool`
           END
       ) = 200
       AND SUM(`pg`.`chance` = `b`.`chance`) = 200
       AND SUM(`pg`.`description` <=> `b`.`description`) = 200
    FROM `_backup_pool_gameobject_fifty_tattered_chests_20260728` AS `b`
    INNER JOIN `pool_gameobject` AS `pg`
        ON `pg`.`guid` = `b`.`guid`
    INNER JOIN `gameobject` AS `g`
        ON `g`.`guid` = `b`.`guid`
    INNER JOIN `_tmp_fifty_tattered_chest_pools_20260728` AS `m`
        ON `m`.`old_pool` = `b`.`pool_entry`
    LEFT JOIN `_tmp_fifty_tattered_chest_splits_20260728` AS `s`
        ON `s`.`old_pool` = `b`.`pool_entry`
       AND `s`.`map_id` = `g`.`map`
);

-- On the first application all 200 rows are still in their old pool. Permit
-- that exact source state as well as an already applied state.
SET @fifty_tattered_original_members_ok :=
(
    SELECT COUNT(*) = 200
       AND SUM(`pg`.`pool_entry` = `b`.`pool_entry`) = 200
       AND SUM(`pg`.`chance` = `b`.`chance`) = 200
       AND SUM(`pg`.`description` <=> `b`.`description`) = 200
    FROM `_backup_pool_gameobject_fifty_tattered_chests_20260728` AS `b`
    INNER JOIN `pool_gameobject` AS `pg`
        ON `pg`.`guid` = `b`.`guid`
    INNER JOIN `_tmp_fifty_tattered_chest_pools_20260728` AS `m`
        ON `m`.`old_pool` = `b`.`pool_entry`
);

SET @fifty_tattered_no_foreign_target_members_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_gameobject` AS `pg`
    INNER JOIN `_tmp_fifty_tattered_chest_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pg`.`pool_entry`
    LEFT JOIN `_backup_pool_gameobject_fifty_tattered_chests_20260728` AS `b`
        ON `b`.`guid` = `pg`.`guid`
    WHERE `b`.`guid` IS NULL
);

SET @fifty_tattered_apply_ok :=
    @fifty_tattered_manifest_ok
    AND @fifty_tattered_template_backup_ok
    AND @fifty_tattered_member_backup_ok
    AND @fifty_tattered_four_members_each_ok
    AND @fifty_tattered_split_ok
    AND @fifty_tattered_no_hierarchy_ok
    AND @fifty_tattered_target_templates_ok
    AND @fifty_tattered_no_foreign_target_members_ok
    AND
    (
        @fifty_tattered_original_members_ok
        OR @fifty_tattered_current_members_ok
    );

START TRANSACTION;

INSERT INTO `pool_template` (`entry`,`max_limit`,`description`)
SELECT `s`.`new_pool`,1,`s`.`description`
FROM `_tmp_fifty_tattered_chest_splits_20260728` AS `s`
WHERE @fifty_tattered_apply_ok = 1
  AND NOT EXISTS
  (
      SELECT 1
      FROM `pool_template` AS `pt`
      WHERE `pt`.`entry` = `s`.`new_pool`
  );

UPDATE `pool_gameobject` AS `pg`
INNER JOIN `_backup_pool_gameobject_fifty_tattered_chests_20260728` AS `b`
    ON `b`.`guid` = `pg`.`guid`
INNER JOIN `gameobject` AS `g`
    ON `g`.`guid` = `b`.`guid`
INNER JOIN `_tmp_fifty_tattered_chest_pools_20260728` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
INNER JOIN `_tmp_fifty_tattered_chest_splits_20260728` AS `s`
    ON `s`.`old_pool` = `b`.`pool_entry`
   AND `s`.`map_id` = `g`.`map`
SET `pg`.`pool_entry` = `s`.`new_pool`
WHERE @fifty_tattered_apply_ok = 1
  AND `g`.`map` <> `m`.`canonical_map`;

COMMIT;

SELECT @fifty_tattered_apply_ok AS `apply_guard`,
       (SELECT COUNT(*)
        FROM `_backup_pool_template_fifty_tattered_chests_20260728`)
           AS `template_backup_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_gameobject_fifty_tattered_chests_20260728`)
           AS `member_backup_rows`,
       (SELECT COUNT(*)
        FROM `_tmp_fifty_tattered_chest_splits_20260728`)
           AS `new_pool_count`;

DROP TEMPORARY TABLE `_tmp_fifty_tattered_chest_splits_20260728`;
DROP TEMPORARY TABLE `_tmp_fifty_tattered_chest_all_pool_ids_20260728`;
DROP TEMPORARY TABLE `_tmp_fifty_tattered_chest_pools_20260728`;
