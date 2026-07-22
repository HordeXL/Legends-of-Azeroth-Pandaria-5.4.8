-- Restore the two Scarlet Monastery Fool's Cap spawns to their existing,
-- correctly named pool instead of leaving them in the Shado-Pan Monastery
-- Snow Lily pool.
--
-- The preserved 5.4.8 databases all contain the same merge error:
--   pool 30134 = Snow Lily Shado-Pan Monastery (map 959)
--   pool 30135 = Fool's Cap Scarlet Monastery (map 1004, left empty)
--   GUIDs 534424/534425 = Fool's Cap on map 1004, assigned to 30134
-- No spawn or pool template is deleted; only the two exact memberships move.

-- CREATE TABLE implicitly commits in MySQL 5.7, so preserve the exact source
-- rows before starting the guarded data transaction.
CREATE TABLE IF NOT EXISTS `_backup_pool_gameobject_30134_30135_20260722`
LIKE `pool_gameobject`;

INSERT IGNORE INTO `_backup_pool_gameobject_30134_30135_20260722`
SELECT *
FROM `pool_gameobject`
WHERE `guid` IN (534424, 534425)
  AND `pool_entry` = 30134
  AND `chance` = 0
  AND `description` IS NULL;

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
JOIN `gameobject` AS `g`
  ON `g`.`guid` = `pg`.`guid`
 AND `g`.`id` = 209355
 AND `g`.`map` = 1004
JOIN `pool_template` AS `wrong_pool`
  ON `wrong_pool`.`entry` = 30134
 AND `wrong_pool`.`max_limit` = 2
 AND `wrong_pool`.`description` = 'Snow Lily Shado-Pan Monastery'
JOIN `pool_template` AS `correct_pool`
  ON `correct_pool`.`entry` = 30135
 AND `correct_pool`.`max_limit` = 2
 AND `correct_pool`.`description` = 'Fool''s Cap Scarlet Monastery'
SET `pg`.`pool_entry` = 30135
WHERE @fools_cap_pool_backup_ok = 1
  AND `pg`.`guid` IN (534424, 534425)
  AND `pg`.`pool_entry` = 30134
  AND `pg`.`chance` = 0
  AND `pg`.`description` IS NULL;

COMMIT;
