-- Split the final 194 source-exact, safely classifiable cross-map
-- "Master pool" hierarchies.
-- All 774 child links and their chance/description values are preserved.

CREATE TABLE IF NOT EXISTS `_backup_pool_manifest_final_194_master_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    `canonical_map` SMALLINT UNSIGNED NOT NULL,
    `max_limit` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_mother`)
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_final_194_master_ids_20260729`;
CREATE TEMPORARY TABLE `_tmp_final_194_master_ids_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_mother`)
);

INSERT INTO `_tmp_final_194_master_ids_20260729` (`old_mother`) VALUES
(9572),(9573),(9574),(9575),(9576),(9577),(9578),(9579),(9580),(9581),
(9582),(9583),(9584),(9585),(9586),(9587),(9588),(9590),(9591),(9593),
(9594),(9596),(9597),(9598),(9600),(9601),(9602),(9603),(9605),(9606),
(9607),(9608),(9609),(9610),(9611),(9612),(9613),(9614),(9615),(9616),
(9617),(9618),(9619),(9620),(9621),(9622),(9623),(9624),(9625),(9626),
(9627),(9630),(9631),(9632),(9633),(9634),(9635),(9636),(9637),(9638),
(9639),(9640),(9641),(9642),(9643),(9644),(9645),(9646),(9647),(9648),
(9649),(9650),(9651),(9652),(9653),(9654),(9655),(9656),(9657),(9658),
(9660),(9661),(9662),(9663),(9664),(9665),(9666),(9667),(9668),(9669),
(9670),(9671),(9672),(9673),(9674),(9675),(9676),(9677),(9678),(9679),
(9680),(9682),(9684),(9685),(9686),(9687),(9688),(9689),(9690),(9691),
(9692),(9693),(9694),(9695),(9696),(9697),(9699),(9700),(9701),(9702),
(9703),(9704),(9705),(9706),(9707),(9708),(9709),(9710),(9711),(9712),
(9713),(9714),(9715),(9716),(9717),(9718),(9719),(9723),(9724),(9725),
(9727),(9729),(9730),(9731),(9733),(9734),(9736),(9737),(9738),(9739),
(9740),(9742),(9744),(9745),(9746),(9747),(9748),(9749),(9750),(9751),
(9752),(9753),(9755),(9756),(9757),(9759),(9760),(9761),(9762),(9763),
(9764),(9766),(9769),(9774),(9775),(9776),(9777),(9778),(9779),(9780),
(9781),(9782),(9784),(9785),(9786),(9787),(9788),(9789),(9790),(9791),
(9793),(9797),(9824),(9857);

SET @final_194_master_manifest_empty :=
(
    SELECT COUNT(*) = 0
    FROM `_backup_pool_manifest_final_194_master_20260729`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_final_194_initial_maps_20260729`;
CREATE TEMPORARY TABLE `_tmp_final_194_initial_maps_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    `child_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_mother`,`child_pool`,`map_id`)
);

INSERT INTO `_tmp_final_194_initial_maps_20260729`
(`old_mother`,`child_pool`,`map_id`)
SELECT `pp`.`mother_pool`,`pp`.`pool_id`,`g`.`map`
FROM `_tmp_final_194_master_ids_20260729` AS `i`
INNER JOIN `pool_pool` AS `pp` ON `pp`.`mother_pool` = `i`.`old_mother`
INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`pool_entry` = `pp`.`pool_id`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `pg`.`guid`
WHERE @final_194_master_manifest_empty = 1
GROUP BY `pp`.`mother_pool`,`pp`.`pool_id`,`g`.`map`;

INSERT INTO `_backup_pool_manifest_final_194_master_20260729`
(`old_mother`,`canonical_map`,`max_limit`,`description`)
SELECT `i`.`old_mother`,MIN(`lm`.`map_id`),
       `pt`.`max_limit`,`pt`.`description`
FROM `_tmp_final_194_master_ids_20260729` AS `i`
INNER JOIN `_tmp_final_194_initial_maps_20260729` AS `lm`
    ON `lm`.`old_mother` = `i`.`old_mother`
INNER JOIN `pool_template` AS `pt` ON `pt`.`entry` = `i`.`old_mother`
WHERE @final_194_master_manifest_empty = 1
GROUP BY `i`.`old_mother`,`pt`.`max_limit`,`pt`.`description`;

CREATE TABLE IF NOT EXISTS `_backup_pool_template_final_194_master_20260729`
LIKE `pool_template`;

INSERT INTO `_backup_pool_template_final_194_master_20260729`
SELECT `pt`.*
FROM `pool_template` AS `pt`
INNER JOIN `_backup_pool_manifest_final_194_master_20260729` AS `m`
    ON `m`.`old_mother` = `pt`.`entry`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_template_final_194_master_20260729` AS `b`
    WHERE `b`.`entry` = `pt`.`entry`
);

CREATE TABLE IF NOT EXISTS `_backup_pool_pool_final_194_master_20260729`
LIKE `pool_pool`;

INSERT INTO `_backup_pool_pool_final_194_master_20260729`
SELECT `pp`.*
FROM `pool_pool` AS `pp`
INNER JOIN `_backup_pool_manifest_final_194_master_20260729` AS `m`
    ON `m`.`old_mother` = `pp`.`mother_pool`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_pool_final_194_master_20260729` AS `b`
    WHERE `b`.`pool_id` = `pp`.`pool_id`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_final_194_master_maps_20260729`;
CREATE TEMPORARY TABLE `_tmp_final_194_master_maps_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    `child_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_mother`,`child_pool`,`map_id`)
);

INSERT INTO `_tmp_final_194_master_maps_20260729`
(`old_mother`,`child_pool`,`map_id`)
SELECT `b`.`mother_pool`,`b`.`pool_id`,`g`.`map`
FROM `_backup_pool_pool_final_194_master_20260729` AS `b`
INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`pool_entry` = `b`.`pool_id`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `pg`.`guid`
GROUP BY `b`.`mother_pool`,`b`.`pool_id`,`g`.`map`;

DROP TEMPORARY TABLE IF EXISTS `_tmp_final_194_master_splits_20260729`;
CREATE TEMPORARY TABLE `_tmp_final_194_master_splits_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_mother` MEDIUMINT UNSIGNED NOT NULL,
    `max_limit` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_mother`,`map_id`),
    UNIQUE KEY (`new_mother`)
);

INSERT INTO `_tmp_final_194_master_splits_20260729`
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
FROM `_tmp_final_194_master_maps_20260729` AS `lm`
INNER JOIN `_backup_pool_manifest_final_194_master_20260729` AS `m`
    ON `m`.`old_mother` = `lm`.`old_mother`
WHERE `lm`.`map_id` <> `m`.`canonical_map`
  AND `lm`.`map_id` IN (0,1,530,571);

SET @final_194_master_manifest_ok :=
(
    SELECT COUNT(*) = 194
       AND SUM(`max_limit` = 2) = 194
       AND SUM(`description` = 'Master pool') = 194
       AND SUM(`canonical_map` = 0) = 189
       AND SUM(`canonical_map` = 1) = 5
    FROM `_backup_pool_manifest_final_194_master_20260729`
);

SET @final_194_master_backups_ok :=
(
    SELECT
        (SELECT COUNT(*)
         FROM `_backup_pool_template_final_194_master_20260729`) = 194
        AND
        (SELECT COUNT(*)
         FROM `_backup_pool_pool_final_194_master_20260729`) = 774
        AND
        (SELECT COUNT(DISTINCT `pool_id`)
         FROM `_backup_pool_pool_final_194_master_20260729`) = 774
        AND
        (SELECT SUM(`chance` = 0)
         FROM `_backup_pool_pool_final_194_master_20260729`) = 774
        AND
        (SELECT SUM(COALESCE(`description`,'') = '')
         FROM `_backup_pool_pool_final_194_master_20260729`) = 774
);

SET @final_194_master_template_values_ok :=
(
    SELECT COUNT(*) = 194
       AND SUM(`b`.`max_limit` = `m`.`max_limit`) = 194
       AND SUM(`b`.`description` <=> `m`.`description`) = 194
    FROM `_backup_pool_template_final_194_master_20260729` AS `b`
    INNER JOIN `_backup_pool_manifest_final_194_master_20260729` AS `m`
        ON `m`.`old_mother` = `b`.`entry`
);

SET @final_194_master_children_ok :=
(
    SELECT
        (SELECT COUNT(*)
         FROM `_backup_pool_pool_final_194_master_20260729` AS `b`
         INNER JOIN `pool_template` AS `pt`
             ON `pt`.`entry` = `b`.`pool_id`) = 774
        AND
        (SELECT COUNT(*)
         FROM `pool_creature` AS `pc`
         INNER JOIN `_backup_pool_pool_final_194_master_20260729` AS `b`
             ON `b`.`pool_id` = `pc`.`pool_entry`) = 0
        AND
        (SELECT COUNT(*)
         FROM `pool_gameobject` AS `pg`
         INNER JOIN `_backup_pool_pool_final_194_master_20260729` AS `b`
             ON `b`.`pool_id` = `pg`.`pool_entry`) = 2745
);

SET @final_194_master_maps_ok :=
(
    SELECT COUNT(*) = 774
       AND COUNT(DISTINCT `child_pool`) = 774
       AND SUM(`map_id` = 0) = 370
       AND SUM(`map_id` = 1) = 397
       AND SUM(`map_id` = 530) = 7
    FROM `_tmp_final_194_master_maps_20260729`
);

SET @final_194_master_split_ok :=
(
    SELECT COUNT(*) = 195
       AND COUNT(DISTINCT `new_mother`) = 195
       AND SUM(`map_id` = 1) = 189
       AND SUM(`map_id` = 530) = 6
    FROM `_tmp_final_194_master_splits_20260729`
);

SET @final_194_master_moved_ok :=
(
    SELECT COUNT(*) = 774
       AND SUM(`lm`.`map_id` <> `m`.`canonical_map`) = 390
       AND SUM(`lm`.`map_id` = 1
               AND `lm`.`map_id` <> `m`.`canonical_map`) = 383
       AND SUM(`lm`.`map_id` = 530
               AND `lm`.`map_id` <> `m`.`canonical_map`) = 7
    FROM `_tmp_final_194_master_maps_20260729` AS `lm`
    INNER JOIN `_backup_pool_manifest_final_194_master_20260729` AS `m`
        ON `m`.`old_mother` = `lm`.`old_mother`
);

SET @final_194_master_no_upper_refs_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_pool` AS `pp`
    INNER JOIN `_backup_pool_manifest_final_194_master_20260729` AS `m`
        ON `m`.`old_mother` = `pp`.`pool_id`
);

SET @final_194_master_target_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_final_194_master_splits_20260729` AS `s`
        ON `s`.`new_mother` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> `s`.`max_limit`
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @final_194_master_no_foreign_targets_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_pool` AS `pp`
    INNER JOIN `_tmp_final_194_master_splits_20260729` AS `s`
        ON `s`.`new_mother` = `pp`.`mother_pool`
        OR `s`.`new_mother` = `pp`.`pool_id`
    LEFT JOIN `_backup_pool_pool_final_194_master_20260729` AS `b`
        ON `b`.`pool_id` = `pp`.`pool_id`
    WHERE `b`.`pool_id` IS NULL
       OR `s`.`new_mother` = `pp`.`pool_id`
);

SET @final_194_master_original_state_ok :=
(
    SELECT COUNT(*) = 774
       AND SUM(`pp`.`mother_pool` = `b`.`mother_pool`) = 774
       AND SUM(`pp`.`chance` = `b`.`chance`) = 774
       AND SUM(`pp`.`description` <=> `b`.`description`) = 774
    FROM `_backup_pool_pool_final_194_master_20260729` AS `b`
    INNER JOIN `pool_pool` AS `pp` ON `pp`.`pool_id` = `b`.`pool_id`
);

SET @final_194_master_final_state_ok :=
(
    SELECT COUNT(*) = 774
       AND SUM(
           `pp`.`mother_pool` =
           CASE WHEN `lm`.`map_id` = `m`.`canonical_map`
                THEN `m`.`old_mother` ELSE `s`.`new_mother` END
       ) = 774
       AND SUM(`pp`.`chance` = `b`.`chance`) = 774
       AND SUM(`pp`.`description` <=> `b`.`description`) = 774
    FROM `_backup_pool_pool_final_194_master_20260729` AS `b`
    INNER JOIN `pool_pool` AS `pp` ON `pp`.`pool_id` = `b`.`pool_id`
    INNER JOIN `_tmp_final_194_master_maps_20260729` AS `lm`
        ON `lm`.`old_mother` = `b`.`mother_pool`
       AND `lm`.`child_pool` = `b`.`pool_id`
    INNER JOIN `_backup_pool_manifest_final_194_master_20260729` AS `m`
        ON `m`.`old_mother` = `b`.`mother_pool`
    LEFT JOIN `_tmp_final_194_master_splits_20260729` AS `s`
        ON `s`.`old_mother` = `b`.`mother_pool`
       AND `s`.`map_id` = `lm`.`map_id`
);

SET @final_194_master_apply_ok :=
    @final_194_master_manifest_ok
    AND @final_194_master_backups_ok
    AND @final_194_master_template_values_ok
    AND @final_194_master_children_ok
    AND @final_194_master_maps_ok
    AND @final_194_master_split_ok
    AND @final_194_master_moved_ok
    AND @final_194_master_no_upper_refs_ok
    AND @final_194_master_target_templates_ok
    AND @final_194_master_no_foreign_targets_ok
    AND (@final_194_master_original_state_ok
         OR @final_194_master_final_state_ok);

START TRANSACTION;

INSERT INTO `pool_template` (`entry`,`max_limit`,`description`)
SELECT `s`.`new_mother`,`s`.`max_limit`,`s`.`description`
FROM `_tmp_final_194_master_splits_20260729` AS `s`
WHERE @final_194_master_apply_ok = 1
  AND NOT EXISTS
      (SELECT 1 FROM `pool_template` AS `pt`
       WHERE `pt`.`entry` = `s`.`new_mother`);

UPDATE `pool_pool` AS `pp`
INNER JOIN `_backup_pool_pool_final_194_master_20260729` AS `b`
    ON `b`.`pool_id` = `pp`.`pool_id`
INNER JOIN `_tmp_final_194_master_maps_20260729` AS `lm`
    ON `lm`.`old_mother` = `b`.`mother_pool`
   AND `lm`.`child_pool` = `b`.`pool_id`
INNER JOIN `_backup_pool_manifest_final_194_master_20260729` AS `m`
    ON `m`.`old_mother` = `b`.`mother_pool`
INNER JOIN `_tmp_final_194_master_splits_20260729` AS `s`
    ON `s`.`old_mother` = `b`.`mother_pool`
   AND `s`.`map_id` = `lm`.`map_id`
SET `pp`.`mother_pool` = `s`.`new_mother`
WHERE @final_194_master_apply_ok = 1
  AND `lm`.`map_id` <> `m`.`canonical_map`;

COMMIT;

SELECT @final_194_master_apply_ok AS `apply_guard`,
       (SELECT COUNT(*)
        FROM `_backup_pool_manifest_final_194_master_20260729`)
           AS `manifest_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_template_final_194_master_20260729`)
           AS `template_backup_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_pool_final_194_master_20260729`)
           AS `link_backup_rows`,
       (SELECT COUNT(*) FROM `_tmp_final_194_master_splits_20260729`)
           AS `new_mother_count`,
       (SELECT COUNT(*)
        FROM `_tmp_final_194_master_maps_20260729` AS `lm`
        INNER JOIN `_backup_pool_manifest_final_194_master_20260729` AS `m`
            ON `m`.`old_mother` = `lm`.`old_mother`
        WHERE `lm`.`map_id` <> `m`.`canonical_map`)
           AS `moved_link_rows`;

DROP TEMPORARY TABLE `_tmp_final_194_master_splits_20260729`;
DROP TEMPORARY TABLE `_tmp_final_194_master_maps_20260729`;
DROP TEMPORARY TABLE `_tmp_final_194_initial_maps_20260729`;
DROP TEMPORARY TABLE `_tmp_final_194_master_ids_20260729`;
