-- Exact, idempotent rollback for
-- 2026_07_30_00_world_split_three_description_mapped_master_pools.sql.

SET @three_described_rollback_backup_ok :=
(
    SELECT
        (SELECT COUNT(*)
         FROM `_backup_pool_manifest_three_described_master_20260730`) = 12
        AND
        (SELECT COUNT(*)
         FROM `_backup_pool_template_three_described_master_20260730`) = 15
        AND
        (SELECT COUNT(*)
         FROM `_backup_pool_pool_three_described_master_20260730`) = 12
);

SET @three_described_rollback_links_ok :=
(
    SELECT COUNT(*) = 12
       AND SUM(`pp`.`mother_pool` = `b`.`mother_pool`
               OR `pp`.`mother_pool` = `m`.`new_mother`) = 12
       AND SUM(`pp`.`chance` = `b`.`chance`) = 12
       AND SUM(`pp`.`description` <=> `b`.`description`) = 12
    FROM `_backup_pool_pool_three_described_master_20260730` AS `b`
    INNER JOIN `_backup_pool_manifest_three_described_master_20260730` AS `m`
        ON `m`.`child_pool` = `b`.`pool_id`
    INNER JOIN `pool_pool` AS `pp` ON `pp`.`pool_id` = `b`.`pool_id`
);

SET @three_described_rollback_targets_ok :=
(
    SELECT COUNT(*) = 0
    FROM `pool_template`
    WHERE `entry` IN (209379,209519,209792)
      AND (`max_limit` <> 2
           OR NOT (`description` <=> 'Master pool'))
);

SET @three_described_rollback_no_foreign_ok :=
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

SET @three_described_rollback_ok :=
    @three_described_rollback_backup_ok
    AND @three_described_rollback_links_ok
    AND @three_described_rollback_targets_ok
    AND @three_described_rollback_no_foreign_ok;

START TRANSACTION;

UPDATE `pool_pool` AS `pp`
INNER JOIN `_backup_pool_pool_three_described_master_20260730` AS `b`
    ON `b`.`pool_id` = `pp`.`pool_id`
SET `pp`.`mother_pool` = `b`.`mother_pool`,
    `pp`.`chance` = `b`.`chance`,
    `pp`.`description` = `b`.`description`
WHERE @three_described_rollback_ok = 1;

DELETE `pt`
FROM `pool_template` AS `pt`
WHERE @three_described_rollback_ok = 1
  AND `pt`.`entry` IN (209379,209519,209792)
  AND NOT EXISTS
      (SELECT 1 FROM `pool_pool` AS `pp`
       WHERE `pp`.`pool_id` = `pt`.`entry`
          OR `pp`.`mother_pool` = `pt`.`entry`)
  AND NOT EXISTS
      (SELECT 1 FROM `pool_creature` AS `pc`
       WHERE `pc`.`pool_entry` = `pt`.`entry`)
  AND NOT EXISTS
      (SELECT 1 FROM `pool_gameobject` AS `pg`
       WHERE `pg`.`pool_entry` = `pt`.`entry`)
  AND NOT EXISTS
      (SELECT 1 FROM `pool_quest` AS `pq`
       WHERE `pq`.`pool_entry` = `pt`.`entry`);

COMMIT;

SELECT @three_described_rollback_ok AS `rollback_guard`,
       (SELECT COUNT(*)
        FROM `_backup_pool_manifest_three_described_master_20260730`)
           AS `manifest_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_template_three_described_master_20260730`)
           AS `template_backup_rows`,
       (SELECT COUNT(*)
        FROM `_backup_pool_pool_three_described_master_20260730`)
           AS `link_backup_rows`;
