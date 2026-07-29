-- Split the first 200 source-exact cross-map "Master pool" hierarchies.
-- All 800 child links and their chance/description values are preserved.

CREATE TABLE IF NOT EXISTS `_backup_pool_manifest_first_200_master_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    `canonical_map` SMALLINT UNSIGNED NOT NULL,
    `max_limit` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_mother`)
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_first_200_master_ids_20260729`;
CREATE TEMPORARY TABLE `_tmp_first_200_master_ids_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_mother`)
);

INSERT INTO `_tmp_first_200_master_ids_20260729` (`old_mother`) VALUES
(5625),(5627),(5629),(5632),(5633),(5634),(5635),(5636),(5637),(5639),
(5642),(5643),(5644),(5645),(5646),(5647),(5649),(9122),(9123),(9124),
(9125),(9126),(9127),(9128),(9130),(9131),(9132),(9133),(9134),(9135),
(9136),(9137),(9138),(9140),(9141),(9143),(9144),(9146),(9147),(9148),
(9149),(9150),(9151),(9152),(9154),(9155),(9157),(9158),(9159),(9160),
(9161),(9162),(9163),(9164),(9165),(9167),(9168),(9169),(9170),(9171),
(9172),(9173),(9174),(9175),(9176),(9177),(9178),(9179),(9180),(9181),
(9183),(9184),(9186),(9187),(9188),(9189),(9190),(9191),(9192),(9193),
(9194),(9195),(9196),(9197),(9199),(9200),(9201),(9204),(9207),(9208),
(9209),(9210),(9212),(9213),(9214),(9215),(9216),(9217),(9218),(9219),
(9220),(9221),(9222),(9223),(9224),(9226),(9227),(9228),(9229),(9230),
(9233),(9236),(9237),(9239),(9241),(9242),(9243),(9244),(9246),(9247),
(9248),(9250),(9251),(9252),(9253),(9255),(9256),(9257),(9258),(9259),
(9260),(9261),(9262),(9263),(9264),(9265),(9266),(9267),(9268),(9269),
(9270),(9272),(9274),(9275),(9276),(9277),(9278),(9281),(9282),(9283),
(9284),(9285),(9286),(9287),(9288),(9289),(9290),(9291),(9292),(9293),
(9294),(9295),(9297),(9298),(9299),(9300),(9301),(9302),(9304),(9305),
(9306),(9308),(9309),(9310),(9311),(9313),(9314),(9315),(9316),(9317),
(9319),(9320),(9321),(9322),(9323),(9324),(9326),(9327),(9328),(9329),
(9330),(9331),(9332),(9333),(9334),(9336),(9338),(9339),(9340),(9341);

SET @first_200_master_manifest_empty :=
(
    SELECT COUNT(*) = 0
    FROM `_backup_pool_manifest_first_200_master_20260729`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_first_200_initial_link_maps_20260729`;
CREATE TEMPORARY TABLE `_tmp_first_200_initial_link_maps_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    `child_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_mother`,`child_pool`,`map_id`)
);

INSERT IGNORE INTO `_tmp_first_200_initial_link_maps_20260729`
(`old_mother`,`child_pool`,`map_id`)
SELECT `pp`.`mother_pool`,`pp`.`pool_id`,`c`.`map`
FROM `_tmp_first_200_master_ids_20260729` AS `i`
INNER JOIN `pool_pool` AS `pp` ON `pp`.`mother_pool` = `i`.`old_mother`
INNER JOIN `pool_creature` AS `pc` ON `pc`.`pool_entry` = `pp`.`pool_id`
INNER JOIN `creature` AS `c` ON `c`.`guid` = `pc`.`guid`
WHERE @first_200_master_manifest_empty = 1
GROUP BY `pp`.`mother_pool`,`pp`.`pool_id`,`c`.`map`;

INSERT INTO `_tmp_first_200_initial_link_maps_20260729`
(`old_mother`,`child_pool`,`map_id`)
SELECT `pp`.`mother_pool`,`pp`.`pool_id`,`g`.`map`
FROM `_tmp_first_200_master_ids_20260729` AS `i`
INNER JOIN `pool_pool` AS `pp` ON `pp`.`mother_pool` = `i`.`old_mother`
INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`pool_entry` = `pp`.`pool_id`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `pg`.`guid`
WHERE @first_200_master_manifest_empty = 1
GROUP BY `pp`.`mother_pool`,`pp`.`pool_id`,`g`.`map`;

INSERT INTO `_backup_pool_manifest_first_200_master_20260729`
(`old_mother`,`canonical_map`,`max_limit`,`description`)
SELECT `i`.`old_mother`,MIN(`lm`.`map_id`),
       `pt`.`max_limit`,`pt`.`description`
FROM `_tmp_first_200_master_ids_20260729` AS `i`
INNER JOIN `_tmp_first_200_initial_link_maps_20260729` AS `lm`
    ON `lm`.`old_mother` = `i`.`old_mother`
INNER JOIN `pool_template` AS `pt` ON `pt`.`entry` = `i`.`old_mother`
WHERE @first_200_master_manifest_empty = 1
GROUP BY `i`.`old_mother`,`pt`.`max_limit`,`pt`.`description`;

CREATE TABLE IF NOT EXISTS `_backup_pool_template_first_200_master_20260729`
LIKE `pool_template`;

INSERT INTO `_backup_pool_template_first_200_master_20260729`
SELECT `pt`.*
FROM `pool_template` AS `pt`
INNER JOIN `_backup_pool_manifest_first_200_master_20260729` AS `m`
    ON `m`.`old_mother` = `pt`.`entry`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_template_first_200_master_20260729` AS `b`
    WHERE `b`.`entry` = `pt`.`entry`
);

CREATE TABLE IF NOT EXISTS `_backup_pool_pool_first_200_master_20260729`
LIKE `pool_pool`;

INSERT INTO `_backup_pool_pool_first_200_master_20260729`
SELECT `pp`.*
FROM `pool_pool` AS `pp`
INNER JOIN `_backup_pool_manifest_first_200_master_20260729` AS `m`
    ON `m`.`old_mother` = `pp`.`mother_pool`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_pool_first_200_master_20260729` AS `b`
    WHERE `b`.`pool_id` = `pp`.`pool_id`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_first_200_master_link_maps_20260729`;
CREATE TEMPORARY TABLE `_tmp_first_200_master_link_maps_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    `child_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_mother`,`child_pool`,`map_id`)
);

INSERT IGNORE INTO `_tmp_first_200_master_link_maps_20260729`
(`old_mother`,`child_pool`,`map_id`)
SELECT `b`.`mother_pool`,`b`.`pool_id`,`c`.`map`
FROM `_backup_pool_pool_first_200_master_20260729` AS `b`
INNER JOIN `pool_creature` AS `pc` ON `pc`.`pool_entry` = `b`.`pool_id`
INNER JOIN `creature` AS `c` ON `c`.`guid` = `pc`.`guid`
GROUP BY `b`.`mother_pool`,`b`.`pool_id`,`c`.`map`;

INSERT INTO `_tmp_first_200_master_link_maps_20260729`
(`old_mother`,`child_pool`,`map_id`)
SELECT `b`.`mother_pool`,`b`.`pool_id`,`g`.`map`
FROM `_backup_pool_pool_first_200_master_20260729` AS `b`
INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`pool_entry` = `b`.`pool_id`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `pg`.`guid`
GROUP BY `b`.`mother_pool`,`b`.`pool_id`,`g`.`map`;

DROP TEMPORARY TABLE IF EXISTS `_tmp_first_200_master_splits_20260729`;
CREATE TEMPORARY TABLE `_tmp_first_200_master_splits_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_mother` MEDIUMINT UNSIGNED NOT NULL,
    `max_limit` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_mother`,`map_id`),
    UNIQUE KEY (`new_mother`)
);

INSERT INTO `_tmp_first_200_master_splits_20260729`
(`old_mother`,`map_id`,`new_mother`,`max_limit`,`description`)
SELECT DISTINCT `lm`.`old_mother`,`lm`.`map_id`,
       `lm`.`old_mother` +
           CASE `lm`.`map_id`
               WHEN 0 THEN 100000
               WHEN 1 THEN 200000
               WHEN 530 THEN 300000
               WHEN 571 THEN 400000
           END,
       `m`.`max_limit`,`m`.`description`
FROM `_tmp_first_200_master_link_maps_20260729` AS `lm`
INNER JOIN `_backup_pool_manifest_first_200_master_20260729` AS `m`
    ON `m`.`old_mother` = `lm`.`old_mother`
WHERE `lm`.`map_id` <> `m`.`canonical_map`
  AND `lm`.`map_id` IN (0,1,530,571);

SET @first_200_master_manifest_ok :=
(
    SELECT COUNT(*) = 200
       AND SUM(`max_limit` = 1) = 17
       AND SUM(`max_limit` = 2) = 183
       AND SUM(`description` = 'Master pool') = 200
       AND SUM(`canonical_map` = 0) = 191
       AND SUM(`canonical_map` = 1) = 9
    FROM `_backup_pool_manifest_first_200_master_20260729`
);

SET @first_200_master_template_backup_ok :=
(
    SELECT COUNT(*) = 200
       AND SUM(`b`.`max_limit` = `m`.`max_limit`) = 200
       AND SUM(`b`.`description` <=> `m`.`description`) = 200
    FROM `_backup_pool_template_first_200_master_20260729` AS `b`
    INNER JOIN `_backup_pool_manifest_first_200_master_20260729` AS `m`
        ON `m`.`old_mother` = `b`.`entry`
);

SET @first_200_master_link_backup_ok :=
(
    SELECT COUNT(*) = 800
       AND COUNT(DISTINCT `b`.`pool_id`) = 800
       AND COUNT(DISTINCT `b`.`mother_pool`) = 200
       AND SUM(`b`.`chance` = 0) = 800
       AND SUM(COALESCE(`b`.`description`,'') = '') = 800
    FROM `_backup_pool_pool_first_200_master_20260729` AS `b`
);

SET @first_200_master_child_templates_ok :=
(
    SELECT COUNT(*) = 800
    FROM `_backup_pool_pool_first_200_master_20260729` AS `b`
    INNER JOIN `pool_template` AS `pt` ON `pt`.`entry` = `b`.`pool_id`
);

SET @first_200_master_child_members_ok :=
(
    SELECT
        (SELECT COUNT(*)
         FROM `pool_creature` AS `pc`
         INNER JOIN `_backup_pool_pool_first_200_master_20260729` AS `b`
             ON `b`.`pool_id` = `pc`.`pool_entry`) = 170
        AND
        (SELECT COUNT(*)
         FROM `pool_gameobject` AS `pg`
         INNER JOIN `_backup_pool_pool_first_200_master_20260729` AS `b`
             ON `b`.`pool_id` = `pg`.`pool_entry`) = 1524
);

SET @first_200_master_maps_ok :=
(
    SELECT COUNT(*) = 800
       AND COUNT(DISTINCT `child_pool`) = 800
       AND SUM(`map_id` IN (0,1,530,571)) = 800
    FROM `_tmp_first_200_master_link_maps_20260729`
);

SET @first_200_master_split_ok :=
(
    SELECT COUNT(*) = 227
       AND COUNT(DISTINCT `new_mother`) = 227
       AND SUM(`map_id` = 1) = 173
       AND SUM(`map_id` = 530) = 53
       AND SUM(`map_id` = 571) = 1
    FROM `_tmp_first_200_master_splits_20260729`
);

SET @first_200_master_moved_ok :=
(
    SELECT COUNT(*) = 800
       AND SUM(`lm`.`map_id` <> `m`.`canonical_map`) = 410
       AND SUM(`lm`.`map_id` = 1
               AND `lm`.`map_id` <> `m`.`canonical_map`) = 341
       AND SUM(`lm`.`map_id` = 530
               AND `lm`.`map_id` <> `m`.`canonical_map`) = 68
       AND SUM(`lm`.`map_id` = 571
               AND `lm`.`map_id` <> `m`.`canonical_map`) = 1
    FROM `_tmp_first_200_master_link_maps_20260729` AS `lm`
    INNER JOIN `_backup_pool_manifest_first_200_master_20260729` AS `m`
        ON `m`.`old_mother` = `lm`.`old_mother`
);

SET @first_200_master_no_upper_refs_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_pool` AS `pp`
    INNER JOIN `_backup_pool_manifest_first_200_master_20260729` AS `m`
        ON `m`.`old_mother` = `pp`.`pool_id`
);

SET @first_200_master_target_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_first_200_master_splits_20260729` AS `s`
        ON `s`.`new_mother` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> `s`.`max_limit`
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @first_200_master_no_foreign_target_links_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_pool` AS `pp`
    INNER JOIN `_tmp_first_200_master_splits_20260729` AS `s`
        ON `s`.`new_mother` = `pp`.`mother_pool`
        OR `s`.`new_mother` = `pp`.`pool_id`
    LEFT JOIN `_backup_pool_pool_first_200_master_20260729` AS `b`
        ON `b`.`pool_id` = `pp`.`pool_id`
    WHERE `b`.`pool_id` IS NULL
       OR `s`.`new_mother` = `pp`.`pool_id`
);

SET @first_200_master_original_state_ok :=
(
    SELECT COUNT(*) = 800
       AND SUM(`pp`.`mother_pool` = `b`.`mother_pool`) = 800
       AND SUM(`pp`.`chance` = `b`.`chance`) = 800
       AND SUM(`pp`.`description` <=> `b`.`description`) = 800
    FROM `_backup_pool_pool_first_200_master_20260729` AS `b`
    INNER JOIN `pool_pool` AS `pp` ON `pp`.`pool_id` = `b`.`pool_id`
);

SET @first_200_master_final_state_ok :=
(
    SELECT COUNT(*) = 800
       AND SUM(
           `pp`.`mother_pool` =
           CASE WHEN `lm`.`map_id` = `m`.`canonical_map`
                THEN `m`.`old_mother` ELSE `s`.`new_mother` END
       ) = 800
       AND SUM(`pp`.`chance` = `b`.`chance`) = 800
       AND SUM(`pp`.`description` <=> `b`.`description`) = 800
    FROM `_backup_pool_pool_first_200_master_20260729` AS `b`
    INNER JOIN `pool_pool` AS `pp` ON `pp`.`pool_id` = `b`.`pool_id`
    INNER JOIN `_tmp_first_200_master_link_maps_20260729` AS `lm`
        ON `lm`.`old_mother` = `b`.`mother_pool`
       AND `lm`.`child_pool` = `b`.`pool_id`
    INNER JOIN `_backup_pool_manifest_first_200_master_20260729` AS `m`
        ON `m`.`old_mother` = `b`.`mother_pool`
    LEFT JOIN `_tmp_first_200_master_splits_20260729` AS `s`
        ON `s`.`old_mother` = `b`.`mother_pool`
       AND `s`.`map_id` = `lm`.`map_id`
);

SET @first_200_master_apply_ok :=
    @first_200_master_manifest_ok
    AND @first_200_master_template_backup_ok
    AND @first_200_master_link_backup_ok
    AND @first_200_master_child_templates_ok
    AND @first_200_master_child_members_ok
    AND @first_200_master_maps_ok
    AND @first_200_master_split_ok
    AND @first_200_master_moved_ok
    AND @first_200_master_no_upper_refs_ok
    AND @first_200_master_target_templates_ok
    AND @first_200_master_no_foreign_target_links_ok
    AND (@first_200_master_original_state_ok
         OR @first_200_master_final_state_ok);

START TRANSACTION;

INSERT INTO `pool_template` (`entry`,`max_limit`,`description`)
SELECT `s`.`new_mother`,`s`.`max_limit`,`s`.`description`
FROM `_tmp_first_200_master_splits_20260729` AS `s`
WHERE @first_200_master_apply_ok = 1
  AND NOT EXISTS
      (SELECT 1 FROM `pool_template` AS `pt`
       WHERE `pt`.`entry` = `s`.`new_mother`);

UPDATE `pool_pool` AS `pp`
INNER JOIN `_backup_pool_pool_first_200_master_20260729` AS `b`
    ON `b`.`pool_id` = `pp`.`pool_id`
INNER JOIN `_tmp_first_200_master_link_maps_20260729` AS `lm`
    ON `lm`.`old_mother` = `b`.`mother_pool`
   AND `lm`.`child_pool` = `b`.`pool_id`
INNER JOIN `_backup_pool_manifest_first_200_master_20260729` AS `m`
    ON `m`.`old_mother` = `b`.`mother_pool`
INNER JOIN `_tmp_first_200_master_splits_20260729` AS `s`
    ON `s`.`old_mother` = `b`.`mother_pool`
   AND `s`.`map_id` = `lm`.`map_id`
SET `pp`.`mother_pool` = `s`.`new_mother`
WHERE @first_200_master_apply_ok = 1
  AND `lm`.`map_id` <> `m`.`canonical_map`;

COMMIT;

SELECT @first_200_master_apply_ok AS `apply_guard`,
       (SELECT COUNT(*)
        FROM `_backup_pool_manifest_first_200_master_20260729`)
           AS `manifest_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_template_first_200_master_20260729`)
           AS `template_backup_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_pool_first_200_master_20260729`)
           AS `link_backup_rows`,
       (SELECT COUNT(*) FROM `_tmp_first_200_master_splits_20260729`)
           AS `new_mother_count`,
       (SELECT COUNT(*)
        FROM `_tmp_first_200_master_link_maps_20260729` AS `lm`
        INNER JOIN `_backup_pool_manifest_first_200_master_20260729` AS `m`
            ON `m`.`old_mother` = `lm`.`old_mother`
        WHERE `lm`.`map_id` <> `m`.`canonical_map`)
           AS `moved_link_rows`;

DROP TEMPORARY TABLE `_tmp_first_200_master_splits_20260729`;
DROP TEMPORARY TABLE `_tmp_first_200_master_link_maps_20260729`;
DROP TEMPORARY TABLE `_tmp_first_200_initial_link_maps_20260729`;
DROP TEMPORARY TABLE `_tmp_first_200_master_ids_20260729`;
