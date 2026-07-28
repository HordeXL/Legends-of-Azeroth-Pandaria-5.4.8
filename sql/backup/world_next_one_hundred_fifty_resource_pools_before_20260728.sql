-- Exact, idempotent rollback for
-- 2026_07_28_08_world_split_next_one_hundred_fifty_resource_pools.sql.

DROP TEMPORARY TABLE IF EXISTS `_tmp_next_150_resource_rollback_20260728`;
CREATE TEMPORARY TABLE `_tmp_next_150_resource_rollback_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `canonical_map` SMALLINT UNSIGNED NOT NULL,
    `batch_no` TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_pool`)
);

INSERT INTO `_tmp_next_150_resource_rollback_20260728`
(`old_pool`,`canonical_map`,`batch_no`) VALUES
(11372,1,1),(11375,0,1),(11377,1,1),(11378,0,1),(11381,1,1),
(11382,0,1),(11384,1,1),(11385,1,1),(11386,1,1),(11387,0,1),
(11388,0,1),(11389,0,1),(11390,1,1),(11391,0,1),(11392,0,1),
(11393,0,1),(11394,0,1),(11396,0,1),(11397,0,1),(11398,0,1),
(11399,1,1),(11400,0,1),(11401,1,1),(11402,0,1),(11404,0,1),
(11406,0,1),(11407,1,1),(11408,0,1),(11410,1,1),(11411,0,1),
(11412,1,1),(11413,1,1),(11414,0,1),(11424,1,1),(11438,1,1),
(11448,530,1),(11449,530,1),(11450,0,1),(11469,0,1),(11472,0,1),
(11473,1,1),(11474,1,1),(11475,0,1),(11476,0,1),(11477,1,1),
(11478,0,1),(11479,0,1),(11480,0,1),(11481,0,1),(11482,0,1),
(11483,0,2),(11484,1,2),(11486,1,2),(11487,0,2),(11488,1,2),
(11489,0,2),(11490,0,2),(11491,1,2),(11493,1,2),(11494,0,2),
(11495,0,2),(11496,0,2),(11497,0,2),(11498,0,2),(11499,0,2),
(11500,1,2),(11501,0,2),(11502,1,2),(11503,0,2),(11504,0,2),
(11505,1,2),(11506,0,2),(11507,1,2),(11509,1,2),(11511,1,2),
(11513,0,2),(11521,1,2),(11526,530,2),(11535,1,2),(11536,1,2),
(11543,530,2),(11544,0,2),(11562,530,2),(11565,0,2),(11568,1,2),
(11569,0,2),(11570,1,2),(11571,0,2),(11572,0,2),(11573,1,2),
(11574,1,2),(11575,0,2),(11576,0,2),(11577,1,2),(11578,1,2),
(11579,0,2),(11580,0,2),(11582,1,2),(11583,1,2),(11584,0,2),
(11585,1,3),(11586,1,3),(11588,0,3),(11590,1,3),(11591,0,3),
(11592,0,3),(11593,1,3),(11594,0,3),(11595,0,3),(11596,0,3),
(11597,0,3),(11598,0,3),(11599,0,3),(11600,1,3),(11602,0,3),
(11603,0,3),(11604,1,3),(11605,0,3),(11606,0,3),(11607,0,3),
(11608,0,3),(11616,1,3),(11623,530,3),(11641,1,3),(11644,530,3),
(11645,0,3),(11662,530,3),(11665,0,3),(11668,1,3),(11669,0,3),
(11670,1,3),(11671,0,3),(11672,0,3),(11673,1,3),(11674,1,3),
(11675,0,3),(11676,0,3),(11677,1,3),(11679,0,3),(11680,1,3),
(11681,0,3),(11682,0,3),(11683,1,3),(11684,1,3),(11685,0,3),
(11686,0,3),(11687,1,3),(11688,1,3),(11689,0,3),(11690,0,3);

DROP TEMPORARY TABLE IF EXISTS `_tmp_next_150_rollback_splits_20260728`;
CREATE TEMPORARY TABLE `_tmp_next_150_rollback_splits_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_pool` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    `batch_no` TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_pool`,`map_id`),
    UNIQUE KEY (`new_pool`)
);

INSERT INTO `_tmp_next_150_rollback_splits_20260728`
(`old_pool`,`map_id`,`new_pool`,`description`,`batch_no`)
SELECT `b`.`pool_entry`,`g`.`map`,
       `b`.`pool_entry` +
           CASE `g`.`map`
               WHEN 0 THEN 100000
               WHEN 1 THEN 200000
               WHEN 530 THEN 300000
           END,
       MIN(`b`.`description`),`m`.`batch_no`
FROM `_backup_pool_gameobject_next_150_resources_20260728` AS `b`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
INNER JOIN `_tmp_next_150_resource_rollback_20260728` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
WHERE `g`.`map` <> `m`.`canonical_map`
  AND `g`.`map` IN (0,1,530)
GROUP BY `b`.`pool_entry`,`g`.`map`,`m`.`batch_no`;

SET @next_150_rollback_backup_ok :=
(
    SELECT
        (SELECT COUNT(*) FROM `_backup_pool_template_next_150_resources_20260728`) = 150
        AND
        (SELECT COUNT(*) FROM `_backup_pool_gameobject_next_150_resources_20260728`) = 600
        AND
        (SELECT COUNT(*) FROM `_tmp_next_150_rollback_splits_20260728`) = 150
);

SET @next_150_rollback_members_ok :=
(
    SELECT COUNT(*) = 600
       AND SUM(
           `pg`.`pool_entry` = `b`.`pool_entry`
           OR `pg`.`pool_entry` = `s`.`new_pool`
       ) = 600
       AND SUM(`pg`.`chance` = `b`.`chance`) = 600
       AND SUM(`pg`.`description` <=> `b`.`description`) = 600
    FROM `_backup_pool_gameobject_next_150_resources_20260728` AS `b`
    INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`guid` = `b`.`guid`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    LEFT JOIN `_tmp_next_150_rollback_splits_20260728` AS `s`
        ON `s`.`old_pool` = `b`.`pool_entry` AND `s`.`map_id` = `g`.`map`
);

SET @next_150_rollback_no_foreign_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_gameobject` AS `pg`
    INNER JOIN `_tmp_next_150_rollback_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pg`.`pool_entry`
    LEFT JOIN `_backup_pool_gameobject_next_150_resources_20260728` AS `b`
        ON `b`.`guid` = `pg`.`guid`
    WHERE `b`.`guid` IS NULL
);

SET @next_150_rollback_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_next_150_rollback_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> 2
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @next_150_rollback_ok :=
    @next_150_rollback_backup_ok
    AND @next_150_rollback_members_ok
    AND @next_150_rollback_no_foreign_ok
    AND @next_150_rollback_templates_ok;

START TRANSACTION;

UPDATE `pool_gameobject` AS `pg`
INNER JOIN `_backup_pool_gameobject_next_150_resources_20260728` AS `b`
    ON `b`.`guid` = `pg`.`guid`
SET `pg`.`pool_entry` = `b`.`pool_entry`,
    `pg`.`chance` = `b`.`chance`,
    `pg`.`description` = `b`.`description`
WHERE @next_150_rollback_ok = 1;

DELETE `pt`
FROM `pool_template` AS `pt`
INNER JOIN `_tmp_next_150_rollback_splits_20260728` AS `s`
    ON `s`.`new_pool` = `pt`.`entry`
WHERE @next_150_rollback_ok = 1
  AND NOT EXISTS
      (SELECT 1 FROM `pool_gameobject` AS `pg`
       WHERE `pg`.`pool_entry` = `pt`.`entry`)
  AND NOT EXISTS
      (SELECT 1 FROM `pool_pool` AS `pp`
       WHERE `pp`.`pool_id` = `pt`.`entry`
          OR `pp`.`mother_pool` = `pt`.`entry`);

COMMIT;

SELECT @next_150_rollback_ok AS `rollback_guard`,
       (SELECT COUNT(*) FROM `_backup_pool_template_next_150_resources_20260728`)
           AS `template_backup_rows`,
       (SELECT COUNT(*) FROM `_backup_pool_gameobject_next_150_resources_20260728`)
           AS `member_backup_rows`;

DROP TEMPORARY TABLE `_tmp_next_150_rollback_splits_20260728`;
DROP TEMPORARY TABLE `_tmp_next_150_resource_rollback_20260728`;
