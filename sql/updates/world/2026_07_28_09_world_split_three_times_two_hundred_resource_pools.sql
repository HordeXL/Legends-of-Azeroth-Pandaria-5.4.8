-- Split exactly three audited batches of 200 source-described cross-map pools.
-- Batch 1 and most of batch 2 are GO 2045/max_limit 2; the remaining pools are
-- GO 1618/max_limit 3. Every selected pool has exactly four members.
-- All 2,400 members are preserved; no spawn or membership is deleted.

CREATE TABLE IF NOT EXISTS `_backup_pool_manifest_three_x_200_resources_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `canonical_map` SMALLINT UNSIGNED NOT NULL,
    `max_limit` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    `batch_no` TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_pool`),
    KEY (`batch_no`)
);

SET @three_x_200_manifest_empty :=
(
    SELECT COUNT(*) = 0
    FROM `_backup_pool_manifest_three_x_200_resources_20260728`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_three_x_200_discovery_20260728`;
CREATE TEMPORARY TABLE `_tmp_three_x_200_discovery_20260728`
(
    `seq` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `canonical_map` SMALLINT UNSIGNED NOT NULL,
    `max_limit` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`seq`),
    UNIQUE KEY (`old_pool`)
);

INSERT INTO `_tmp_three_x_200_discovery_20260728`
(`old_pool`,`canonical_map`,`max_limit`,`description`)
SELECT `pt`.`entry`,
       CAST(SUBSTRING_INDEX(`pt`.`description`,'map=',-1) AS UNSIGNED),
       `pt`.`max_limit`,`pt`.`description`
FROM `pool_template` AS `pt`
STRAIGHT_JOIN `pool_gameobject` AS `pg` ON `pg`.`pool_entry` = `pt`.`entry`
STRAIGHT_JOIN `gameobject` AS `g` ON `g`.`guid` = `pg`.`guid`
WHERE @three_x_200_manifest_empty = 1
  AND `pt`.`entry` > 11690
  AND `pt`.`entry` < 100000
  AND
  (
      (`pt`.`max_limit` = 2 AND `pt`.`description` LIKE 'GO 2045,%')
      OR
      (`pt`.`max_limit` = 3 AND `pt`.`description` LIKE 'GO 1618,%')
  )
GROUP BY `pt`.`entry`,`pt`.`max_limit`,`pt`.`description`
HAVING COUNT(*) = 4
   AND SUM(`g`.`map` IN (0,1,530)) = 4
   AND SUM(
       `pg`.`description` =
       CONCAT(SUBSTRING_INDEX(`pt`.`description`,'map=',1),'map=',`g`.`map`)
   ) = 4
   AND SUM(
       `g`.`map` =
       CAST(SUBSTRING_INDEX(`pt`.`description`,'map=',-1) AS UNSIGNED)
   ) > 0
   AND COUNT(DISTINCT `g`.`map`) > 1
ORDER BY `pt`.`entry`
LIMIT 600;

INSERT INTO `_backup_pool_manifest_three_x_200_resources_20260728`
(`old_pool`,`canonical_map`,`max_limit`,`description`,`batch_no`)
SELECT `old_pool`,`canonical_map`,`max_limit`,`description`,
       FLOOR((`seq` - 1) / 200) + 1
FROM `_tmp_three_x_200_discovery_20260728`;

CREATE TABLE IF NOT EXISTS `_backup_pool_template_three_x_200_resources_20260728`
LIKE `pool_template`;

INSERT INTO `_backup_pool_template_three_x_200_resources_20260728`
SELECT `pt`.*
FROM `pool_template` AS `pt`
INNER JOIN `_backup_pool_manifest_three_x_200_resources_20260728` AS `m`
    ON `m`.`old_pool` = `pt`.`entry`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_template_three_x_200_resources_20260728` AS `b`
    WHERE `b`.`entry` = `pt`.`entry`
);

CREATE TABLE IF NOT EXISTS `_backup_pool_gameobject_three_x_200_resources_20260728`
LIKE `pool_gameobject`;

INSERT INTO `_backup_pool_gameobject_three_x_200_resources_20260728`
SELECT `pg`.*
FROM `pool_gameobject` AS `pg`
INNER JOIN `_backup_pool_manifest_three_x_200_resources_20260728` AS `m`
    ON `m`.`old_pool` = `pg`.`pool_entry`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_gameobject_three_x_200_resources_20260728` AS `b`
    WHERE `b`.`guid` = `pg`.`guid`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_three_x_200_splits_20260728`;
CREATE TEMPORARY TABLE `_tmp_three_x_200_splits_20260728`
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

INSERT INTO `_tmp_three_x_200_splits_20260728`
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

SET @three_x_200_manifest_ok :=
(
    SELECT COUNT(*) = 600
       AND SUM(`batch_no` = 1) = 200
       AND SUM(`batch_no` = 2) = 200
       AND SUM(`batch_no` = 3) = 200
       AND SUM(`max_limit` = 2) = 387
       AND SUM(`max_limit` = 3) = 213
    FROM `_backup_pool_manifest_three_x_200_resources_20260728`
);

SET @three_x_200_template_backup_ok :=
(
    SELECT COUNT(*) = 600
       AND SUM(`b`.`max_limit` = `m`.`max_limit`) = 600
       AND SUM(`b`.`description` <=> `m`.`description`) = 600
       AND SUM(
           CAST(SUBSTRING_INDEX(`b`.`description`,'map=',-1) AS UNSIGNED)
           = `m`.`canonical_map`
       ) = 600
    FROM `_backup_pool_template_three_x_200_resources_20260728` AS `b`
    INNER JOIN `_backup_pool_manifest_three_x_200_resources_20260728` AS `m`
        ON `m`.`old_pool` = `b`.`entry`
);

SET @three_x_200_member_backup_ok :=
(
    SELECT COUNT(*) = 2400
       AND COUNT(DISTINCT `b`.`pool_entry`) = 600
       AND SUM(
           `b`.`description` =
           CONCAT(
               SUBSTRING_INDEX(`m`.`description`,'map=',1),
               'map=',`g`.`map`
           )
       ) = 2400
       AND SUM(`g`.`map` IN (0,1,530)) = 2400
    FROM `_backup_pool_gameobject_three_x_200_resources_20260728` AS `b`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    INNER JOIN `_backup_pool_manifest_three_x_200_resources_20260728` AS `m`
        ON `m`.`old_pool` = `b`.`pool_entry`
);

SET @three_x_200_four_members_ok :=
(
    SELECT COUNT(*) = 600
       AND MIN(`x`.`member_count`) = 4
       AND MAX(`x`.`member_count`) = 4
    FROM
    (
        SELECT `b`.`pool_entry`,COUNT(*) AS `member_count`
        FROM `_backup_pool_gameobject_three_x_200_resources_20260728` AS `b`
        GROUP BY `b`.`pool_entry`
    ) AS `x`
);

SET @three_x_200_split_ok :=
(
    SELECT COUNT(*) = 636
       AND SUM(`batch_no` = 1) = 202
       AND SUM(`batch_no` = 2) = 204
       AND SUM(`batch_no` = 3) = 230
    FROM `_tmp_three_x_200_splits_20260728`
);

SET @three_x_200_moved_ok :=
(
    SELECT COUNT(*) = 2400
       AND SUM(`g`.`map` <> `m`.`canonical_map`) = 1039
       AND SUM(`m`.`batch_no` = 1 AND `g`.`map` <> `m`.`canonical_map`) = 338
       AND SUM(`m`.`batch_no` = 2 AND `g`.`map` <> `m`.`canonical_map`) = 337
       AND SUM(`m`.`batch_no` = 3 AND `g`.`map` <> `m`.`canonical_map`) = 364
    FROM `_backup_pool_gameobject_three_x_200_resources_20260728` AS `b`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    INNER JOIN `_backup_pool_manifest_three_x_200_resources_20260728` AS `m`
        ON `m`.`old_pool` = `b`.`pool_entry`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_three_x_200_all_pool_ids_20260728`;
CREATE TEMPORARY TABLE `_tmp_three_x_200_all_pool_ids_20260728`
(
    `pool_id` MEDIUMINT UNSIGNED NOT NULL,
    PRIMARY KEY (`pool_id`)
);

INSERT INTO `_tmp_three_x_200_all_pool_ids_20260728` (`pool_id`)
SELECT `old_pool`
FROM `_backup_pool_manifest_three_x_200_resources_20260728`;

INSERT INTO `_tmp_three_x_200_all_pool_ids_20260728` (`pool_id`)
SELECT `new_pool` FROM `_tmp_three_x_200_splits_20260728`;

SET @three_x_200_no_hierarchy_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_pool` AS `pp`
    INNER JOIN `_tmp_three_x_200_all_pool_ids_20260728` AS `p`
        ON `p`.`pool_id` = `pp`.`pool_id`
        OR `p`.`pool_id` = `pp`.`mother_pool`
);

SET @three_x_200_target_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_three_x_200_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> `s`.`max_limit`
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @three_x_200_original_state_ok :=
(
    SELECT COUNT(*) = 2400
       AND SUM(`pg`.`pool_entry` = `b`.`pool_entry`) = 2400
       AND SUM(`pg`.`chance` = `b`.`chance`) = 2400
       AND SUM(`pg`.`description` <=> `b`.`description`) = 2400
    FROM `_backup_pool_gameobject_three_x_200_resources_20260728` AS `b`
    INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`guid` = `b`.`guid`
);

SET @three_x_200_final_state_ok :=
(
    SELECT COUNT(*) = 2400
       AND SUM(
           `pg`.`pool_entry` =
           CASE WHEN `g`.`map` = `m`.`canonical_map`
                THEN `m`.`old_pool` ELSE `s`.`new_pool` END
       ) = 2400
       AND SUM(`pg`.`chance` = `b`.`chance`) = 2400
       AND SUM(`pg`.`description` <=> `b`.`description`) = 2400
    FROM `_backup_pool_gameobject_three_x_200_resources_20260728` AS `b`
    INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`guid` = `b`.`guid`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    INNER JOIN `_backup_pool_manifest_three_x_200_resources_20260728` AS `m`
        ON `m`.`old_pool` = `b`.`pool_entry`
    LEFT JOIN `_tmp_three_x_200_splits_20260728` AS `s`
        ON `s`.`old_pool` = `b`.`pool_entry` AND `s`.`map_id` = `g`.`map`
);

SET @three_x_200_no_foreign_members_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_gameobject` AS `pg`
    INNER JOIN `_tmp_three_x_200_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pg`.`pool_entry`
    LEFT JOIN `_backup_pool_gameobject_three_x_200_resources_20260728` AS `b`
        ON `b`.`guid` = `pg`.`guid`
    WHERE `b`.`guid` IS NULL
);

SET @three_x_200_apply_ok :=
    @three_x_200_manifest_ok
    AND @three_x_200_template_backup_ok
    AND @three_x_200_member_backup_ok
    AND @three_x_200_four_members_ok
    AND @three_x_200_split_ok
    AND @three_x_200_moved_ok
    AND @three_x_200_no_hierarchy_ok
    AND @three_x_200_target_templates_ok
    AND @three_x_200_no_foreign_members_ok
    AND (@three_x_200_original_state_ok OR @three_x_200_final_state_ok);

START TRANSACTION;

INSERT INTO `pool_template` (`entry`,`max_limit`,`description`)
SELECT `s`.`new_pool`,`s`.`max_limit`,`s`.`description`
FROM `_tmp_three_x_200_splits_20260728` AS `s`
WHERE @three_x_200_apply_ok = 1
  AND NOT EXISTS
      (SELECT 1 FROM `pool_template` AS `pt`
       WHERE `pt`.`entry` = `s`.`new_pool`);

UPDATE `pool_gameobject` AS `pg`
INNER JOIN `_backup_pool_gameobject_three_x_200_resources_20260728` AS `b`
    ON `b`.`guid` = `pg`.`guid`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
INNER JOIN `_backup_pool_manifest_three_x_200_resources_20260728` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
INNER JOIN `_tmp_three_x_200_splits_20260728` AS `s`
    ON `s`.`old_pool` = `b`.`pool_entry` AND `s`.`map_id` = `g`.`map`
SET `pg`.`pool_entry` = `s`.`new_pool`
WHERE @three_x_200_apply_ok = 1
  AND `g`.`map` <> `m`.`canonical_map`;

COMMIT;

SELECT @three_x_200_apply_ok AS `apply_guard`,
       (SELECT COUNT(*) FROM `_backup_pool_manifest_three_x_200_resources_20260728`)
           AS `manifest_rows`,
       (SELECT COUNT(*) FROM `_backup_pool_template_three_x_200_resources_20260728`)
           AS `template_backup_rows`,
       (SELECT COUNT(*) FROM `_backup_pool_gameobject_three_x_200_resources_20260728`)
           AS `member_backup_rows`,
       (SELECT COUNT(*) FROM `_tmp_three_x_200_splits_20260728`)
           AS `new_pool_count`;

SELECT `m`.`batch_no`,COUNT(DISTINCT `m`.`old_pool`) AS `pool_count`,
       COUNT(*) AS `member_rows`,
       SUM(`g`.`map` <> `m`.`canonical_map`) AS `moved_members`
FROM `_backup_pool_manifest_three_x_200_resources_20260728` AS `m`
INNER JOIN `_backup_pool_gameobject_three_x_200_resources_20260728` AS `b`
    ON `b`.`pool_entry` = `m`.`old_pool`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
GROUP BY `m`.`batch_no`
ORDER BY `m`.`batch_no`;

SELECT `batch_no`,COUNT(*) AS `new_pool_count`
FROM `_tmp_three_x_200_splits_20260728`
GROUP BY `batch_no`
ORDER BY `batch_no`;

DROP TEMPORARY TABLE `_tmp_three_x_200_all_pool_ids_20260728`;
DROP TEMPORARY TABLE `_tmp_three_x_200_splits_20260728`;
DROP TEMPORARY TABLE `_tmp_three_x_200_discovery_20260728`;
