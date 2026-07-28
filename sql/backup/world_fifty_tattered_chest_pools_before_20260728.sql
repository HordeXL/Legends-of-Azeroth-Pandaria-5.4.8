-- Exact, idempotent rollback for
-- 2026_07_28_02_world_split_fifty_cross_map_tattered_chest_pools.sql.

DROP TEMPORARY TABLE IF EXISTS `_tmp_fifty_tattered_chest_rollback_20260728`;
CREATE TEMPORARY TABLE `_tmp_fifty_tattered_chest_rollback_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `canonical_map` SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (`old_pool`)
);

INSERT INTO `_tmp_fifty_tattered_chest_rollback_20260728`
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

DROP TEMPORARY TABLE IF EXISTS `_tmp_fifty_tattered_chest_rollback_splits_20260728`;
CREATE TEMPORARY TABLE `_tmp_fifty_tattered_chest_rollback_splits_20260728`
(
    `old_pool` MEDIUMINT UNSIGNED NOT NULL,
    `map_id` SMALLINT UNSIGNED NOT NULL,
    `new_pool` MEDIUMINT UNSIGNED NOT NULL,
    `description` VARCHAR(255) NULL,
    PRIMARY KEY (`old_pool`,`map_id`),
    UNIQUE KEY (`new_pool`)
);

INSERT INTO `_tmp_fifty_tattered_chest_rollback_splits_20260728`
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
INNER JOIN `_tmp_fifty_tattered_chest_rollback_20260728` AS `m`
    ON `m`.`old_pool` = `b`.`pool_entry`
WHERE `g`.`map` <> `m`.`canonical_map`
  AND `g`.`map` IN (0,1,530)
GROUP BY `b`.`pool_entry`,`g`.`map`;

SET @fifty_tattered_rollback_backup_ok :=
(
    SELECT
        (SELECT COUNT(*)
         FROM `_backup_pool_template_fifty_tattered_chests_20260728`) = 50
        AND
        (SELECT COUNT(*)
         FROM `_backup_pool_gameobject_fifty_tattered_chests_20260728`) = 200
        AND
        (SELECT COUNT(*)
         FROM `_tmp_fifty_tattered_chest_rollback_splits_20260728`) = 62
);

SET @fifty_tattered_rollback_members_ok :=
(
    SELECT COUNT(*) = 200
       AND SUM(
           `pg`.`pool_entry` = `b`.`pool_entry`
           OR `pg`.`pool_entry` = `s`.`new_pool`
       ) = 200
    FROM `_backup_pool_gameobject_fifty_tattered_chests_20260728` AS `b`
    INNER JOIN `pool_gameobject` AS `pg`
        ON `pg`.`guid` = `b`.`guid`
    INNER JOIN `gameobject` AS `g`
        ON `g`.`guid` = `b`.`guid`
    INNER JOIN `_tmp_fifty_tattered_chest_rollback_20260728` AS `m`
        ON `m`.`old_pool` = `b`.`pool_entry`
    LEFT JOIN `_tmp_fifty_tattered_chest_rollback_splits_20260728` AS `s`
        ON `s`.`old_pool` = `b`.`pool_entry`
       AND `s`.`map_id` = `g`.`map`
);

SET @fifty_tattered_rollback_no_foreign_members_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_gameobject` AS `pg`
    INNER JOIN `_tmp_fifty_tattered_chest_rollback_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pg`.`pool_entry`
    LEFT JOIN `_backup_pool_gameobject_fifty_tattered_chests_20260728` AS `b`
        ON `b`.`guid` = `pg`.`guid`
    WHERE `b`.`guid` IS NULL
);

SET @fifty_tattered_rollback_templates_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template` AS `pt`
    INNER JOIN `_tmp_fifty_tattered_chest_rollback_splits_20260728` AS `s`
        ON `s`.`new_pool` = `pt`.`entry`
    WHERE `pt`.`max_limit` <> 1
       OR NOT (`pt`.`description` <=> `s`.`description`)
);

SET @fifty_tattered_rollback_ok :=
    @fifty_tattered_rollback_backup_ok
    AND @fifty_tattered_rollback_members_ok
    AND @fifty_tattered_rollback_no_foreign_members_ok
    AND @fifty_tattered_rollback_templates_ok;

START TRANSACTION;

UPDATE `pool_gameobject` AS `pg`
INNER JOIN `_backup_pool_gameobject_fifty_tattered_chests_20260728` AS `b`
    ON `b`.`guid` = `pg`.`guid`
SET `pg`.`pool_entry` = `b`.`pool_entry`,
    `pg`.`chance` = `b`.`chance`,
    `pg`.`description` = `b`.`description`
WHERE @fifty_tattered_rollback_ok = 1;

DELETE `pt`
FROM `pool_template` AS `pt`
INNER JOIN `_tmp_fifty_tattered_chest_rollback_splits_20260728` AS `s`
    ON `s`.`new_pool` = `pt`.`entry`
WHERE @fifty_tattered_rollback_ok = 1
  AND NOT EXISTS
  (
      SELECT 1
      FROM `pool_gameobject` AS `pg`
      WHERE `pg`.`pool_entry` = `pt`.`entry`
  )
  AND NOT EXISTS
  (
      SELECT 1
      FROM `pool_pool` AS `pp`
      WHERE `pp`.`pool_id` = `pt`.`entry`
         OR `pp`.`mother_pool` = `pt`.`entry`
  );

COMMIT;

SELECT @fifty_tattered_rollback_ok AS `rollback_guard`,
       (SELECT COUNT(*)
        FROM `_backup_pool_template_fifty_tattered_chests_20260728`)
           AS `template_backup_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_gameobject_fifty_tattered_chests_20260728`)
           AS `member_backup_rows`;

DROP TEMPORARY TABLE `_tmp_fifty_tattered_chest_rollback_splits_20260728`;
DROP TEMPORARY TABLE `_tmp_fifty_tattered_chest_rollback_20260728`;
