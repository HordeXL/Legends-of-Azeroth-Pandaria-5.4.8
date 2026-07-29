-- Split the second 200 source-exact cross-map "Master pool" hierarchies.
-- All 800 child links and their chance/description values are preserved.

CREATE TABLE IF NOT EXISTS `_backup_pool_manifest_second_200_master_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    `canonical_map` SMALLINT UNSIGNED NOT NULL,
    `max_limit` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_mother`)
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_second_200_master_ids_20260729`;
CREATE TEMPORARY TABLE `_tmp_second_200_master_ids_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_mother`)
);

INSERT INTO `_tmp_second_200_master_ids_20260729` (`old_mother`) VALUES
(9342),(9343),(9344),(9345),(9346),(9347),(9348),(9349),(9350),(9351),
(9352),(9353),(9354),(9356),(9357),(9358),(9359),(9360),(9361),(9362),
(9363),(9364),(9365),(9367),(9368),(9369),(9371),(9372),(9373),(9374),
(9375),(9376),(9377),(9378),(9380),(9381),(9382),(9383),(9384),(9385),
(9386),(9387),(9389),(9390),(9391),(9392),(9394),(9395),(9396),(9397),
(9398),(9399),(9400),(9401),(9402),(9403),(9404),(9405),(9406),(9407),
(9408),(9409),(9410),(9411),(9412),(9413),(9414),(9415),(9416),(9417),
(9418),(9419),(9421),(9422),(9423),(9424),(9425),(9426),(9427),(9429),
(9430),(9431),(9432),(9433),(9434),(9435),(9436),(9437),(9438),(9439),
(9441),(9442),(9443),(9444),(9445),(9446),(9448),(9449),(9450),(9451),
(9452),(9453),(9454),(9455),(9456),(9457),(9458),(9460),(9461),(9462),
(9463),(9465),(9466),(9467),(9468),(9469),(9470),(9471),(9472),(9473),
(9475),(9476),(9477),(9478),(9479),(9480),(9481),(9482),(9483),(9484),
(9485),(9486),(9487),(9488),(9491),(9492),(9493),(9494),(9495),(9496),
(9497),(9498),(9499),(9500),(9501),(9502),(9503),(9504),(9505),(9506),
(9507),(9508),(9509),(9510),(9511),(9512),(9513),(9514),(9515),(9518),
(9520),(9521),(9522),(9523),(9525),(9526),(9527),(9528),(9530),(9531),
(9532),(9534),(9535),(9536),(9537),(9538),(9539),(9542),(9543),(9544),
(9545),(9546),(9547),(9548),(9552),(9553),(9554),(9555),(9557),(9559),
(9560),(9561),(9562),(9563),(9564),(9565),(9567),(9568),(9569),(9570);

SET @second_200_master_manifest_empty :=
(
    SELECT COUNT(*) = 0
    FROM `_backup_pool_manifest_second_200_master_20260729`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_second_200_initial_maps_20260729`;
CREATE TEMPORARY TABLE `_tmp_second_200_initial_maps_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    `child_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_mother`,`child_pool`,`map_id`)
);

INSERT INTO `_tmp_second_200_initial_maps_20260729`
(`old_mother`,`child_pool`,`map_id`)
SELECT `pp`.`mother_pool`,`pp`.`pool_id`,`g`.`map`
FROM `_tmp_second_200_master_ids_20260729` AS `i`
INNER JOIN `pool_pool` AS `pp` ON `pp`.`mother_pool` = `i`.`old_mother`
INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`pool_entry` = `pp`.`pool_id`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `pg`.`guid`
WHERE @second_200_master_manifest_empty = 1
GROUP BY `pp`.`mother_pool`,`pp`.`pool_id`,`g`.`map`;

INSERT INTO `_backup_pool_manifest_second_200_master_20260729`
(`old_mother`,`canonical_map`,`max_limit`,`description`)
SELECT `i`.`old_mother`,MIN(`lm`.`map_id`),
       `pt`.`max_limit`,`pt`.`description`
FROM `_tmp_second_200_master_ids_20260729` AS `i`
INNER JOIN `_tmp_second_200_initial_maps_20260729` AS `lm`
    ON `lm`.`old_mother` = `i`.`old_mother`
INNER JOIN `pool_template` AS `pt` ON `pt`.`entry` = `i`.`old_mother`
WHERE @second_200_master_manifest_empty = 1
GROUP BY `i`.`old_mother`,`pt`.`max_limit`,`pt`.`description`;

CREATE TABLE IF NOT EXISTS `_backup_pool_template_second_200_master_20260729`
LIKE `pool_template`;

INSERT INTO `_backup_pool_template_second_200_master_20260729`
SELECT `pt`.*
FROM `pool_template` AS `pt`
INNER JOIN `_backup_pool_manifest_second_200_master_20260729` AS `m`
    ON `m`.`old_mother` = `pt`.`entry`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_template_second_200_master_20260729` AS `b`
    WHERE `b`.`entry` = `pt`.`entry`
);

CREATE TABLE IF NOT EXISTS `_backup_pool_pool_second_200_master_20260729`
LIKE `pool_pool`;

INSERT INTO `_backup_pool_pool_second_200_master_20260729`
SELECT `pp`.*
FROM `pool_pool` AS `pp`
INNER JOIN `_backup_pool_manifest_second_200_master_20260729` AS `m`
    ON `m`.`old_mother` = `pp`.`mother_pool`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_pool_pool_second_200_master_20260729` AS `b`
    WHERE `b`.`pool_id` = `pp`.`pool_id`
);

DROP TEMPORARY TABLE IF EXISTS `_tmp_second_200_master_maps_20260729`;
CREATE TEMPORARY TABLE `_tmp_second_200_master_maps_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    `child_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_mother`,`child_pool`,`map_id`)
);

INSERT INTO `_tmp_second_200_master_maps_20260729`
(`old_mother`,`child_pool`,`map_id`)
SELECT `b`.`mother_pool`,`b`.`pool_id`,`g`.`map`
FROM `_backup_pool_pool_second_200_master_20260729` AS `b`
INNER JOIN `pool_gameobject` AS `pg` ON `pg`.`pool_entry` = `b`.`pool_id`
INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `pg`.`guid`
GROUP BY `b`.`mother_pool`,`b`.`pool_id`,`g`.`map`;

DROP TEMPORARY TABLE IF EXISTS `_tmp_second_200_master_splits_20260729`;
CREATE TEMPORARY TABLE `_tmp_second_200_master_splits_20260729`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_mother` MEDIUMINT UNSIGNED NOT NULL,
    `max_limit` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_mother`,`map_id`),
    UNIQUE KEY (`new_mother`)
);

INSERT INTO `_tmp_second_200_master_splits_20260729`
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
FROM `_tmp_second_200_master_maps_20260729` AS `lm`
INNER JOIN `_backup_pool_manifest_second_200_master_20260729` AS `m`
    ON `m`.`old_mother` = `lm`.`old_mother`
WHERE `lm`.`map_id` <> `m`.`canonical_map`
  AND `lm`.`map_id` IN (0,1,530,571);

SET @second_200_master_manifest_ok :=
(
    SELECT COUNT(*) = 200
       AND SUM(`max_limit` = 2) = 200
       AND SUM(`description` = 'Master pool') = 200
       AND SUM(`canonical_map` = 0) = 200
    FROM `_backup_pool_manifest_second_200_master_20260729`
);

SET @second_200_master_backups_ok :=
(
    SELECT
        (SELECT COUNT(*)
         FROM `_backup_pool_template_second_200_master_20260729`) = 200
        AND
        (SELECT COUNT(*)
         FROM `_backup_pool_pool_second_200_master_20260729`) = 800
        AND
        (SELECT COUNT(DISTINCT `pool_id`)
         FROM `_backup_pool_pool_second_200_master_20260729`) = 800
        AND
        (SELECT SUM(`chance` = 0)
         FROM `_backup_pool_pool_second_200_master_20260729`) = 800
        AND
        (SELECT SUM(COALESCE(`description`,'') = '')
         FROM `_backup_pool_pool_second_200_master_20260729`) = 800
);

SET @second_200_master_template_values_ok :=
(
    SELECT COUNT(*) = 200
       AND SUM(`b`.`max_limit` = `m`.`max_limit`) = 200
       AND SUM(`b`.`description` <=> `m`.`description`) = 200
    FROM `_backup_pool_template_second_200_master_20260729` AS `b`
    INNER JOIN `_backup_pool_manifest_second_200_master_20260729` AS `m`
        ON `m`.`old_mother` = `b`.`entry`
);

SET @second_200_master_children_ok :=
(
    SELECT
        (SELECT COUNT(*)
         FROM `_backup_pool_pool_second_200_master_20260729` AS `b`
         INNER JOIN `pool_template` AS `pt`
             ON `pt`.`entry` = `b`.`pool_id`) = 800
        AND
        (SELECT COUNT(*)
         FROM `pool_creature` AS `pc`
         INNER JOIN `_backup_pool_pool_second_200_master_20260729` AS `b`
             ON `b`.`pool_id` = `pc`.`pool_entry`) = 0
        AND
        (SELECT COUNT(*)
         FROM `pool_gameobject` AS `pg`
         INNER JOIN `_backup_pool_pool_second_200_master_20260729` AS `b`
             ON `b`.`pool_id` = `pg`.`pool_entry`) = 3200
);

SET @second_200_master_maps_ok :=
(
    SELECT COUNT(*) = 800
       AND COUNT(DISTINCT `child_pool`) = 800
       AND SUM(`map_id` IN (0,1)) = 800
    FROM `_tmp_second_200_master_maps_20260729`
);

SET @second_200_master_split_ok :=
(
    SELECT COUNT(*) = 200
       AND COUNT(DISTINCT `new_mother`) = 200
       AND SUM(`map_id` = 1) = 200
    FROM `_tmp_second_200_master_splits_20260729`
);

SET @second_200_master_moved_ok :=
(
    SELECT COUNT(*) = 800
       AND SUM(`lm`.`map_id` <> `m`.`canonical_map`) = 365
       AND SUM(`lm`.`map_id` = 1
               AND `lm`.`map_id` <> `m`.`canonical_map`) = 365
    FROM `_tmp_second_200_master_maps_20260729` AS `lm`
    INNER JOIN `_backup_pool_manifest_second_200_master_20260729` AS `m`
        ON `m`.`old_mother` = `lm`.`old_mother`
);

SET @second_200_master_no_upper_refs_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_pool` AS `pp`
    INNER JOIN `_backup_pool_manifest_second_200_master_20260729` AS `m`
        ON `m`.`old_mother` = `pp`.`pool_id`
);

SET @second_200_master_target_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_second_200_master_splits_20260729` AS `s`
        ON `s`.`new_mother` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> `s`.`max_limit`
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @second_200_master_no_foreign_targets_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_pool` AS `pp`
    INNER JOIN `_tmp_second_200_master_splits_20260729` AS `s`
        ON `s`.`new_mother` = `pp`.`mother_pool`
        OR `s`.`new_mother` = `pp`.`pool_id`
    LEFT JOIN `_backup_pool_pool_second_200_master_20260729` AS `b`
        ON `b`.`pool_id` = `pp`.`pool_id`
    WHERE `b`.`pool_id` IS NULL
       OR `s`.`new_mother` = `pp`.`pool_id`
);

SET @second_200_master_original_state_ok :=
(
    SELECT COUNT(*) = 800
       AND SUM(`pp`.`mother_pool` = `b`.`mother_pool`) = 800
       AND SUM(`pp`.`chance` = `b`.`chance`) = 800
       AND SUM(`pp`.`description` <=> `b`.`description`) = 800
    FROM `_backup_pool_pool_second_200_master_20260729` AS `b`
    INNER JOIN `pool_pool` AS `pp` ON `pp`.`pool_id` = `b`.`pool_id`
);

SET @second_200_master_final_state_ok :=
(
    SELECT COUNT(*) = 800
       AND SUM(
           `pp`.`mother_pool` =
           CASE WHEN `lm`.`map_id` = `m`.`canonical_map`
                THEN `m`.`old_mother` ELSE `s`.`new_mother` END
       ) = 800
       AND SUM(`pp`.`chance` = `b`.`chance`) = 800
       AND SUM(`pp`.`description` <=> `b`.`description`) = 800
    FROM `_backup_pool_pool_second_200_master_20260729` AS `b`
    INNER JOIN `pool_pool` AS `pp` ON `pp`.`pool_id` = `b`.`pool_id`
    INNER JOIN `_tmp_second_200_master_maps_20260729` AS `lm`
        ON `lm`.`old_mother` = `b`.`mother_pool`
       AND `lm`.`child_pool` = `b`.`pool_id`
    INNER JOIN `_backup_pool_manifest_second_200_master_20260729` AS `m`
        ON `m`.`old_mother` = `b`.`mother_pool`
    LEFT JOIN `_tmp_second_200_master_splits_20260729` AS `s`
        ON `s`.`old_mother` = `b`.`mother_pool`
       AND `s`.`map_id` = `lm`.`map_id`
);

SET @second_200_master_apply_ok :=
    @second_200_master_manifest_ok
    AND @second_200_master_backups_ok
    AND @second_200_master_template_values_ok
    AND @second_200_master_children_ok
    AND @second_200_master_maps_ok
    AND @second_200_master_split_ok
    AND @second_200_master_moved_ok
    AND @second_200_master_no_upper_refs_ok
    AND @second_200_master_target_templates_ok
    AND @second_200_master_no_foreign_targets_ok
    AND (@second_200_master_original_state_ok
         OR @second_200_master_final_state_ok);

START TRANSACTION;

INSERT INTO `pool_template` (`entry`,`max_limit`,`description`)
SELECT `s`.`new_mother`,`s`.`max_limit`,`s`.`description`
FROM `_tmp_second_200_master_splits_20260729` AS `s`
WHERE @second_200_master_apply_ok = 1
  AND NOT EXISTS
      (SELECT 1 FROM `pool_template` AS `pt`
       WHERE `pt`.`entry` = `s`.`new_mother`);

UPDATE `pool_pool` AS `pp`
INNER JOIN `_backup_pool_pool_second_200_master_20260729` AS `b`
    ON `b`.`pool_id` = `pp`.`pool_id`
INNER JOIN `_tmp_second_200_master_maps_20260729` AS `lm`
    ON `lm`.`old_mother` = `b`.`mother_pool`
   AND `lm`.`child_pool` = `b`.`pool_id`
INNER JOIN `_backup_pool_manifest_second_200_master_20260729` AS `m`
    ON `m`.`old_mother` = `b`.`mother_pool`
INNER JOIN `_tmp_second_200_master_splits_20260729` AS `s`
    ON `s`.`old_mother` = `b`.`mother_pool`
   AND `s`.`map_id` = `lm`.`map_id`
SET `pp`.`mother_pool` = `s`.`new_mother`
WHERE @second_200_master_apply_ok = 1
  AND `lm`.`map_id` <> `m`.`canonical_map`;

COMMIT;

SELECT @second_200_master_apply_ok AS `apply_guard`,
       (SELECT COUNT(*)
        FROM `_backup_pool_manifest_second_200_master_20260729`)
           AS `manifest_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_template_second_200_master_20260729`)
           AS `template_backup_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_pool_second_200_master_20260729`)
           AS `link_backup_rows`,
       (SELECT COUNT(*) FROM `_tmp_second_200_master_splits_20260729`)
           AS `new_mother_count`,
       (SELECT COUNT(*)
        FROM `_tmp_second_200_master_maps_20260729` AS `lm`
        INNER JOIN `_backup_pool_manifest_second_200_master_20260729` AS `m`
            ON `m`.`old_mother` = `lm`.`old_mother`
        WHERE `lm`.`map_id` <> `m`.`canonical_map`)
           AS `moved_link_rows`;

DROP TEMPORARY TABLE `_tmp_second_200_master_splits_20260729`;
DROP TEMPORARY TABLE `_tmp_second_200_master_maps_20260729`;
DROP TEMPORARY TABLE `_tmp_second_200_initial_maps_20260729`;
DROP TEMPORARY TABLE `_tmp_second_200_master_ids_20260729`;
