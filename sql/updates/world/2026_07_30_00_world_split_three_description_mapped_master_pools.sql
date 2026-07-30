-- Split the final three cross-map Master pool hierarchies.
-- The three memberless children are assigned only from their exact
-- source pool_template descriptions; no member row is invented or deleted.

CREATE TABLE IF NOT EXISTS `_backup_pool_manifest_three_described_master_20260730`
(
    `old_mother` MEDIUMINT UNSIGNED NOT NULL,
    `child_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_mother` MEDIUMINT UNSIGNED NOT NULL,
    PRIMARY KEY (`child_pool`),
    KEY (`old_mother`,`map_id`)
);

INSERT INTO `_backup_pool_manifest_three_described_master_20260730`
(`old_mother`,`child_pool`,`map_id`,`new_mother`) VALUES
(9379,7153,1,209379),
(9379,7154,1,209379),
(9379,7155,0,9379),
(9379,7156,1,209379),
(9519,7713,1,209519),
(9519,7714,1,209519),
(9519,7715,0,9519),
(9519,7716,0,9519),
(9792,8805,1,209792),
(9792,8806,0,9792),
(9792,8807,0,9792),
(9792,8808,530,9792)
ON DUPLICATE KEY UPDATE
    `old_mother` = VALUES(`old_mother`),
    `map_id` = VALUES(`map_id`),
    `new_mother` = VALUES(`new_mother`);

CREATE TABLE IF NOT EXISTS `_backup_pool_template_three_described_master_20260730`
LIKE `pool_template`;

INSERT INTO `_backup_pool_template_three_described_master_20260730`
SELECT `pt`.*
FROM `pool_template` AS `pt`
WHERE `pt`.`entry` IN
      (7153,7154,7155,7156,7713,7714,7715,7716,
       8805,8806,8807,8808,9379,9519,9792)
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_pool_template_three_described_master_20260730` AS `b`
       WHERE `b`.`entry` = `pt`.`entry`);

CREATE TABLE IF NOT EXISTS `_backup_pool_pool_three_described_master_20260730`
LIKE `pool_pool`;

INSERT INTO `_backup_pool_pool_three_described_master_20260730`
SELECT `pp`.*
FROM `pool_pool` AS `pp`
WHERE `pp`.`mother_pool` IN (9379,9519,9792)
  AND `pp`.`pool_id` IN
      (7153,7154,7155,7156,7713,7714,7715,7716,
       8805,8806,8807,8808)
  AND NOT EXISTS
      (SELECT 1
       FROM `_backup_pool_pool_three_described_master_20260730` AS `b`
       WHERE `b`.`pool_id` = `pp`.`pool_id`);

SET @three_described_manifest_ok :=
(
    SELECT COUNT(*) = 12
       AND SUM(`old_mother` = 9379
               AND `child_pool` IN (7153,7154,7155,7156)) = 4
       AND SUM(`old_mother` = 9519
               AND `child_pool` IN (7713,7714,7715,7716)) = 4
       AND SUM(`old_mother` = 9792
               AND `child_pool` IN (8805,8806,8807,8808)) = 4
       AND SUM(`map_id` = 0
               AND `new_mother` = `old_mother`) = 5
       AND SUM(`map_id` = 1
               AND `new_mother` IN (209379,209519,209792)) = 6
       AND SUM(`map_id` = 530
               AND `new_mother` = `old_mother`) = 1
    FROM `_backup_pool_manifest_three_described_master_20260730`
);

SET @three_described_template_backup_ok :=
(
    SELECT COUNT(*) = 15
       AND SUM(`entry` IN (9379,9519,9792)
               AND `max_limit` = 2
               AND `description` = 'Master pool') = 3
       AND SUM(`entry` IN (7153,7154,7155,7156)
               AND `max_limit` = 1
               AND `description` =
                   CONCAT('GO 1735,[1733,1734,1732],map=',
                          CASE WHEN `entry` = 7155 THEN 0 ELSE 1 END)) = 4
       AND SUM(`entry` IN (7713,7714,7715,7716)
               AND `max_limit` = 1
               AND `description` =
                   CONCAT('GO 1735,[1733,1734,1732],map=',
                          CASE WHEN `entry` IN (7713,7714)
                               THEN 1 ELSE 0 END)) = 4
       AND SUM(`entry` IN (8805,8806,8807,8808)
               AND `max_limit` = 1
               AND `description` =
                   CONCAT('GO 175404,[2047,2040],map=',
                          CASE `entry`
                              WHEN 8805 THEN 1
                              WHEN 8808 THEN 530
                              ELSE 0
                          END)) = 4
    FROM `_backup_pool_template_three_described_master_20260730`
);

SET @three_described_link_backup_ok :=
(
    SELECT COUNT(*) = 12
       AND SUM(`b`.`mother_pool` = `m`.`old_mother`) = 12
       AND SUM(`b`.`chance` = 0) = 12
       AND SUM(COALESCE(`b`.`description`,'') = '') = 12
    FROM `_backup_pool_pool_three_described_master_20260730` AS `b`
    INNER JOIN `_backup_pool_manifest_three_described_master_20260730` AS `m`
        ON `m`.`child_pool` = `b`.`pool_id`
);

SET @three_described_members_ok :=
(
    SELECT
        (SELECT COUNT(*)
         FROM `pool_gameobject` AS `pg`
         INNER JOIN `_backup_pool_manifest_three_described_master_20260730` AS `m`
             ON `m`.`child_pool` = `pg`.`pool_entry`) = 33
        AND
        (SELECT COUNT(*)
         FROM `pool_gameobject` AS `pg`
         INNER JOIN `_backup_pool_manifest_three_described_master_20260730` AS `m`
             ON `m`.`child_pool` = `pg`.`pool_entry`
         INNER JOIN `gameobject` AS `g` ON `g`.`guid` = `pg`.`guid`
         WHERE `g`.`map` <> `m`.`map_id`) = 0
        AND
        (SELECT COUNT(*)
         FROM `pool_gameobject`
         WHERE `pool_entry` IN (7154,7713,8808)) = 0
        AND
        (SELECT COUNT(*)
         FROM `pool_creature` AS `pc`
         INNER JOIN `_backup_pool_manifest_three_described_master_20260730` AS `m`
             ON `m`.`child_pool` = `pc`.`pool_entry`) = 0
        AND
        (SELECT COUNT(*)
         FROM `pool_quest` AS `pq`
         INNER JOIN `_backup_pool_manifest_three_described_master_20260730` AS `m`
             ON `m`.`child_pool` = `pq`.`pool_entry`) = 0
);

SET @three_described_no_upper_refs_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_pool`
    WHERE `pool_id` IN (9379,9519,9792)
);

SET @three_described_target_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template`
    WHERE `entry` IN (209379,209519,209792)
      AND (`max_limit` <> 2
           OR NOT (`description` <=> 'Master pool'))
);

SET @three_described_no_foreign_targets_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_pool` AS `pp`
    LEFT JOIN `_backup_pool_manifest_three_described_master_20260730` AS `m`
        ON `m`.`child_pool` = `pp`.`pool_id`
    WHERE (`pp`.`mother_pool` IN (209379,209519,209792)
           OR `pp`.`pool_id` IN (209379,209519,209792))
      AND (`m`.`child_pool` IS NULL
           OR `pp`.`pool_id` IN (209379,209519,209792))
);

SET @three_described_original_state_ok :=
(
    SELECT COUNT(*) = 12
       AND SUM(`pp`.`mother_pool` = `b`.`mother_pool`) = 12
       AND SUM(`pp`.`chance` = `b`.`chance`) = 12
       AND SUM(`pp`.`description` <=> `b`.`description`) = 12
    FROM `_backup_pool_pool_three_described_master_20260730` AS `b`
    INNER JOIN `pool_pool` AS `pp` ON `pp`.`pool_id` = `b`.`pool_id`
);

SET @three_described_final_state_ok :=
(
    SELECT COUNT(*) = 12
       AND SUM(`pp`.`mother_pool` = `m`.`new_mother`) = 12
       AND SUM(`pp`.`chance` = `b`.`chance`) = 12
       AND SUM(`pp`.`description` <=> `b`.`description`) = 12
    FROM `_backup_pool_pool_three_described_master_20260730` AS `b`
    INNER JOIN `_backup_pool_manifest_three_described_master_20260730` AS `m`
        ON `m`.`child_pool` = `b`.`pool_id`
    INNER JOIN `pool_pool` AS `pp` ON `pp`.`pool_id` = `b`.`pool_id`
);

SET @three_described_apply_ok :=
    @three_described_manifest_ok
    AND @three_described_template_backup_ok
    AND @three_described_link_backup_ok
    AND @three_described_members_ok
    AND @three_described_no_upper_refs_ok
    AND @three_described_target_templates_ok
    AND @three_described_no_foreign_targets_ok
    AND (@three_described_original_state_ok
         OR @three_described_final_state_ok);

START TRANSACTION;

INSERT INTO `pool_template` (`entry`,`max_limit`,`description`)
SELECT DISTINCT `m`.`new_mother`,2,'Master pool'
FROM `_backup_pool_manifest_three_described_master_20260730` AS `m`
WHERE @three_described_apply_ok = 1
  AND `m`.`new_mother` <> `m`.`old_mother`
  AND NOT EXISTS
      (SELECT 1 FROM `pool_template` AS `pt`
       WHERE `pt`.`entry` = `m`.`new_mother`);

UPDATE `pool_pool` AS `pp`
INNER JOIN `_backup_pool_manifest_three_described_master_20260730` AS `m`
    ON `m`.`child_pool` = `pp`.`pool_id`
SET `pp`.`mother_pool` = `m`.`new_mother`
WHERE @three_described_apply_ok = 1;

COMMIT;

SELECT @three_described_apply_ok AS `apply_guard`,
       (SELECT COUNT(*)
        FROM `_backup_pool_manifest_three_described_master_20260730`)
           AS `manifest_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_template_three_described_master_20260730`)
           AS `template_backup_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_pool_three_described_master_20260730`)
           AS `link_backup_rows`,
       (SELECT COUNT(DISTINCT `new_mother`)
        FROM `_backup_pool_manifest_three_described_master_20260730`
        WHERE `new_mother` <> `old_mother`)
           AS `new_mother_count`,
       (SELECT COUNT(*)
        FROM `_backup_pool_manifest_three_described_master_20260730`
        WHERE `new_mother` <> `old_mother`)
           AS `moved_link_rows`;
