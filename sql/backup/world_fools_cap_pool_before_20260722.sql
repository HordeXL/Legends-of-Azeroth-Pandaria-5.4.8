-- Exact rollback for
-- 2026_07_22_05_world_fix_scarlet_monastery_fools_cap_pool.sql.

START TRANSACTION;

SET @fools_cap_pool_backup_ok :=
(
    SELECT COUNT(*) = 2
       AND SUM(`guid` = 534424 AND `pool_entry` = 30134
               AND `chance` = 0 AND `description` IS NULL) = 1
       AND SUM(`guid` = 534425 AND `pool_entry` = 30134
               AND `chance` = 0 AND `description` IS NULL) = 1
    FROM `_backup_pool_gameobject_30134_30135_20260722`
);

UPDATE `pool_gameobject` AS `pg`
JOIN `_backup_pool_gameobject_30134_30135_20260722` AS `backup`
  ON `backup`.`guid` = `pg`.`guid`
SET `pg`.`pool_entry` = `backup`.`pool_entry`,
    `pg`.`chance` = `backup`.`chance`,
    `pg`.`description` = `backup`.`description`
WHERE @fools_cap_pool_backup_ok = 1
  AND `pg`.`guid` IN (534424, 534425)
  AND `pg`.`pool_entry` = 30135
  AND `pg`.`chance` = 0
  AND `pg`.`description` IS NULL;

COMMIT;
