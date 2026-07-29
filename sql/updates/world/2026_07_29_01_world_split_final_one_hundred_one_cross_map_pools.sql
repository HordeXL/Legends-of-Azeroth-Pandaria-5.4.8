-- Split the final 101 direct cross-map gameobject pools reported at startup.
-- The explicit list comes from the fully initialized DBErrors.log segment
-- starting at byte 33799646. All 400 original members are preserved.

CREATE TABLE IF NOT EXISTS `_backup_pool_manifest_final_101_cross_map_20260729`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `canonical_map` SMALLINT UNSIGNED NOT NULL,
    `max_limit` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_pool`)
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_final_101_ids_20260729`;
CREATE TEMPORARY TABLE `_tmp_final_101_ids_20260729`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_pool`)
);

INSERT INTO `_tmp_final_101_ids_20260729` (`old_pool`) VALUES
(1002),(1048),(10771),(10776),(10780),(10783),(10784),(10785),
(10872),(10875),(10877),(10879),(10880),(10881),(10962),(10967),
(10970),(10973),(10976),(11061),(11064),(11067),(11068),(11069),
(11152),(11157),(11163),(11165),(11247),(11252),(11258),(11259),
(11273),(11336),(11341),(11344),(11349),(11350),(11379),(11432),
(11440),(11446),(11447),(11528),(11534),(11541),(11542),(11625),
(11634),(11639),(11640),(11642),(11723),(11734),(11735),(11736),
(11813),(11818),(11821),(11824),(11826),(11827),(11906),(11911),
(11913),(11918),(11919),(11920),(11933),(12014),(12017),(12030),
(12101),(12105),(12108),(12110),(12112),(12113),(12125),(12191),
(12200),(12203),(12205),(12206),(12220),(12290),(12293),(12295),
(12298),(12381),(12383),(12384),(12386),(12389),(12390),(12468),
(12473),(12477),(12479),(12482),(13465);

SET @final_101_manifest_empty :=
(
    SELECT COUNT(*) = 0
    FROM `_backup_pool_manifest_final_101_cross_map_20260729`
);

-- Ninety-nine source-described pools identify their canonical map directly.
INSERT INTO `_backup_pool_manifest_final_101_cross_map_20260729`
(`old_pool`,`canonical_map`,`max_limit`,`description`)
SELECT `i`.`old_pool`,
       CAST(SUBSTRING_INDEX(`pt`.`description`,'map=',-1) AS UNSIGNED),
       `pt`.`max_limit`,`pt`.`description`
FROM `_tmp_final_101_ids_20260729` AS `i`
INNER JOIN `pool_template` AS `pt` ON `pt`.`entry` = `i`.`old_pool`
WHERE @final_101_manifest_empty = 1
  AND `pt`.`description` LIKE '%map=%';

-- Pools 1002 and 1048 have an empty source description. They have no
-- hierarchy references; retain the lowest represented map as the canonical
-- instance so the choice is deterministic and reversible.
INSERT INTO `_backup_pool_manifest_final_101_cross_map_20260729`
(`old_pool`,`canonical_map`,`max_limit`,`description`)
SELECT `i`.`old_pool`,MIN(`g`.`map`),`pt`.`max_limit`,`pt`.`description`
FROM `_tmp_final_101_ids_20260729` AS `i`
INNER JOIN `pool_template` AS `pt` ON `pt`.`entry` = `i`.`old_pool`
INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`pool_entry` = `i`.`old_pool`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `pg`.`guid`
WHERE @final_101_manifest_empty = 1
  AND COALESCE(`pt`.`description`,'') = ''
GROUP BY `i`.`old_pool`,`pt`.`max_limit`,`pt`.`description`;

CREATE TABLE IF NOT EXISTS `_backup_pool_template_final_101_cross_map_20260729`
LIKE `pool_template`;

INSERT INTO `_backup_pool_template_final_101_cross_map_20260729`
SELECT `pt`.*
FROM `pool_template` AS `pt`
INNER JOIN `_backup_pool_manifest_final_101_cross_map_20260729` AS `m`
    ON `m`.`old_pool` = `pt`.`entry`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_template_final_101_cross_map_20260729` AS `b`
    WHERE `b`.`entry` = `pt`.`entry`
);

CREATE TABLE IF NOT EXISTS `_backup_pool_gameobject_final_101_cross_map_20260729`
LIKE `pool_gameobject`;

INSERT INTO `_backup_pool_gameobject_final_101_cross_map_20260729`
SELECT `pg`.*
FROM `pool_gameobject` AS `pg`
INNER JOIN `_backup_pool_manifest_final_101_cross_map_20260729` AS `m`
    ON `m`.`old_pool` = `pg`.`pool_entry`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_gameobject_final_101_cross_map_20260729` AS `b`
    WHERE `b`.`guid` = `pg`.`guid`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_final_101_splits_20260729`;
CREATE TEMPORARY TABLE `_tmp_final_101_splits_20260729`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_pool` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    `max_limit` MEDIUMINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_pool`,`map_id`),
    UNIQUE KEY (`new_pool`)
);

INSERT INTO `_tmp_final_101_splits_20260729`
(`old_pool`,`map_id`,`new_pool`,`description`,`max_limit`)
SELECT `b`.`pool_entry`,`g`.`map`,
       `b`.`pool_entry` +
           CASE `g`.`map`
               WHEN 0 THEN 100000
               WHEN 1 THEN 200000
               WHEN 530 THEN 300000
               WHEN 571 THEN 400000
           END,
       MIN(`b`.`description`),`m`.`max_limit`
FROM `_backup_pool_gameobject_final_101_cross_map_20260729` AS `b`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
INNER JOIN `_backup_pool_manifest_final_101_cross_map_20260729` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
WHERE `g`.`map` <> `m`.`canonical_map`
  AND `g`.`map` IN (0,1,530,571)
GROUP BY `b`.`pool_entry`,`g`.`map`,`m`.`max_limit`;

SET @final_101_manifest_ok :=
(
    SELECT COUNT(*) = 101
       AND SUM(COALESCE(`description`,'') = '') = 2
       AND SUM(`max_limit` = 1) = 2
       AND SUM(`max_limit` = 2) = 98
       AND SUM(`max_limit` = 3) = 1
    FROM `_backup_pool_manifest_final_101_cross_map_20260729`
);

SET @final_101_template_backup_ok :=
(
    SELECT COUNT(*) = 101
       AND SUM(`b`.`max_limit` = `m`.`max_limit`) = 101
       AND SUM(`b`.`description` <=> `m`.`description`) = 101
       AND SUM(
           COALESCE(`m`.`description`,'') = ''
           OR CAST(SUBSTRING_INDEX(`b`.`description`,'map=',-1) AS UNSIGNED)
              = `m`.`canonical_map`
       ) = 101
    FROM `_backup_pool_template_final_101_cross_map_20260729` AS `b`
    INNER JOIN `_backup_pool_manifest_final_101_cross_map_20260729` AS `m`
        ON `m`.`old_pool` = `b`.`entry`
);

SET @final_101_member_backup_ok :=
(
    SELECT COUNT(*) = 400
       AND COUNT(DISTINCT `b`.`pool_entry`) = 101
       AND SUM(`g`.`map` IN (0,1,530,571)) = 400
       AND SUM(
           CASE WHEN COALESCE(`m`.`description`,'') = ''
                THEN COALESCE(`b`.`description`,'') = ''
                ELSE `b`.`description` =
                     CONCAT(
                         SUBSTRING_INDEX(`m`.`description`,'map=',1),
                         'map=',`g`.`map`
                     )
           END
       ) = 400
    FROM `_backup_pool_gameobject_final_101_cross_map_20260729` AS `b`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    INNER JOIN `_backup_pool_manifest_final_101_cross_map_20260729` AS `m`
        ON `m`.`old_pool` = `b`.`pool_entry`
);

SET @final_101_member_distribution_ok :=
(
    SELECT COUNT(*) = 101
       AND SUM(`x`.`member_count` = 2) = 2
       AND SUM(`x`.`member_count` = 3) = 2
       AND SUM(`x`.`member_count` = 4) = 96
       AND SUM(`x`.`member_count` = 6) = 1
    FROM
    (
        SELECT `b`.`pool_entry`,COUNT(*) AS `member_count`
        FROM `_backup_pool_gameobject_final_101_cross_map_20260729` AS `b`
        GROUP BY `b`.`pool_entry`
    ) AS `x`
);

SET @final_101_split_ok :=
(
    SELECT COUNT(*) = 118
       AND COUNT(DISTINCT `new_pool`) = 118
    FROM `_tmp_final_101_splits_20260729`
);

SET @final_101_moved_ok :=
(
    SELECT COUNT(*) = 400
       AND SUM(`g`.`map` <> `m`.`canonical_map`) = 200
       AND SUM(`g`.`map` = `m`.`canonical_map`) = 200
    FROM `_backup_pool_gameobject_final_101_cross_map_20260729` AS `b`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    INNER JOIN `_backup_pool_manifest_final_101_cross_map_20260729` AS `m`
        ON `m`.`old_pool` = `b`.`pool_entry`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_final_101_all_pool_ids_20260729`;
CREATE TEMPORARY TABLE `_tmp_final_101_all_pool_ids_20260729`
(
    `pool_id` MEDIUMINT UNSIGNED NOT NULL,
    PRIMARY KEY (`pool_id`)
);

INSERT INTO `_tmp_final_101_all_pool_ids_20260729` (`pool_id`)
SELECT `old_pool`
FROM `_backup_pool_manifest_final_101_cross_map_20260729`;

INSERT INTO `_tmp_final_101_all_pool_ids_20260729` (`pool_id`)
SELECT `new_pool`
FROM `_tmp_final_101_splits_20260729`;

SET @final_101_no_hierarchy_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_pool` AS `pp`
    INNER JOIN `_tmp_final_101_all_pool_ids_20260729` AS `p`
        ON `p`.`pool_id` = `pp`.`pool_id`
        OR `p`.`pool_id` = `pp`.`mother_pool`
);

SET @final_101_target_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_final_101_splits_20260729` AS `s`
        ON `s`.`new_pool` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> `s`.`max_limit`
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @final_101_original_state_ok :=
(
    SELECT COUNT(*) = 400
       AND SUM(`pg`.`pool_entry` = `b`.`pool_entry`) = 400
       AND SUM(`pg`.`chance` = `b`.`chance`) = 400
       AND SUM(`pg`.`description` <=> `b`.`description`) = 400
    FROM `_backup_pool_gameobject_final_101_cross_map_20260729` AS `b`
    INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`guid` = `b`.`guid`
);

SET @final_101_final_state_ok :=
(
    SELECT COUNT(*) = 400
       AND SUM(
           `pg`.`pool_entry` =
           CASE WHEN `g`.`map` = `m`.`canonical_map`
                THEN `m`.`old_pool` ELSE `s`.`new_pool` END
       ) = 400
       AND SUM(`pg`.`chance` = `b`.`chance`) = 400
       AND SUM(`pg`.`description` <=> `b`.`description`) = 400
    FROM `_backup_pool_gameobject_final_101_cross_map_20260729` AS `b`
    INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`guid` = `b`.`guid`
    INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
    INNER JOIN `_backup_pool_manifest_final_101_cross_map_20260729` AS `m`
        ON `m`.`old_pool` = `b`.`pool_entry`
    LEFT JOIN `_tmp_final_101_splits_20260729` AS `s`
        ON `s`.`old_pool` = `b`.`pool_entry`
       AND `s`.`map_id` = `g`.`map`
);

SET @final_101_no_foreign_members_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_gameobject` AS `pg`
    INNER JOIN `_tmp_final_101_splits_20260729` AS `s`
        ON `s`.`new_pool` = `pg`.`pool_entry`
    LEFT JOIN `_backup_pool_gameobject_final_101_cross_map_20260729` AS `b`
        ON `b`.`guid` = `pg`.`guid`
    WHERE `b`.`guid` IS NULL
);

SET @final_101_apply_ok :=
    @final_101_manifest_ok
    AND @final_101_template_backup_ok
    AND @final_101_member_backup_ok
    AND @final_101_member_distribution_ok
    AND @final_101_split_ok
    AND @final_101_moved_ok
    AND @final_101_no_hierarchy_ok
    AND @final_101_target_templates_ok
    AND @final_101_no_foreign_members_ok
    AND (@final_101_original_state_ok OR @final_101_final_state_ok);

START TRANSACTION;

INSERT INTO `pool_template` (`entry`,`max_limit`,`description`)
SELECT `s`.`new_pool`,`s`.`max_limit`,`s`.`description`
FROM `_tmp_final_101_splits_20260729` AS `s`
WHERE @final_101_apply_ok = 1
  AND NOT EXISTS
      (SELECT 1 FROM `pool_template` AS `pt`
       WHERE `pt`.`entry` = `s`.`new_pool`);

UPDATE `pool_gameobject` AS `pg`
INNER JOIN `_backup_pool_gameobject_final_101_cross_map_20260729` AS `b`
    ON `b`.`guid` = `pg`.`guid`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
INNER JOIN `_backup_pool_manifest_final_101_cross_map_20260729` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
INNER JOIN `_tmp_final_101_splits_20260729` AS `s`
    ON `s`.`old_pool` = `b`.`pool_entry`
   AND `s`.`map_id` = `g`.`map`
SET `pg`.`pool_entry` = `s`.`new_pool`
WHERE @final_101_apply_ok = 1
  AND `g`.`map` <> `m`.`canonical_map`;

COMMIT;

SELECT @final_101_apply_ok AS `apply_guard`,
       (SELECT COUNT(*)
        FROM `_backup_pool_manifest_final_101_cross_map_20260729`)
           AS `manifest_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_template_final_101_cross_map_20260729`)
           AS `template_backup_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_gameobject_final_101_cross_map_20260729`)
           AS `member_backup_rows`,
       (SELECT COUNT(*) FROM `_tmp_final_101_splits_20260729`)
           AS `new_pool_count`,
       (SELECT COUNT(*)
        FROM `_backup_pool_gameobject_final_101_cross_map_20260729` AS `b`
        INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `b`.`guid`
        INNER JOIN `_backup_pool_manifest_final_101_cross_map_20260729` AS `m`
            ON `m`.`old_pool` = `b`.`pool_entry`
        WHERE `g`.`map` <> `m`.`canonical_map`)
           AS `moved_member_rows`;

DROP TEMPORARY TABLE `_tmp_final_101_all_pool_ids_20260729`;
DROP TEMPORARY TABLE `_tmp_final_101_splits_20260729`;
DROP TEMPORARY TABLE `_tmp_final_101_ids_20260729`;
