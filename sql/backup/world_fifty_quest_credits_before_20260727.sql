-- Exact, idempotent rollback for
-- 2026_07_27_07_world_fix_fifty_source_backed_quest_credit_spells.sql.

DROP TEMPORARY TABLE IF EXISTS `_tmp_fifty_quest_credit_map_20260727`;
CREATE TEMPORARY TABLE `_tmp_fifty_quest_credit_map_20260727`
(
    `entryorguid`  INT NOT NULL,
    `source_type`  TINYINT UNSIGNED NOT NULL,
    `id`           SMALLINT UNSIGNED NOT NULL,
    `event_type`   TINYINT UNSIGNED NOT NULL,
    `old_credit`   INT UNSIGNED NOT NULL,
    `spell_id`     INT UNSIGNED NOT NULL,
    `new_action`   TINYINT UNSIGNED NOT NULL,
    `target_type`  TINYINT UNSIGNED NOT NULL,
    `target_param1` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`entryorguid`, `source_type`, `id`, `event_type`, `old_credit`)
);

INSERT INTO `_tmp_fifty_quest_credit_map_20260727`
(`entryorguid`,`source_type`,`id`,`event_type`,`old_credit`,`spell_id`,`new_action`,`target_type`,`target_param1`) VALUES
(33081,0,0,8,33081,62265,11,7,0),(43044,0,0,73,43029,80436,85,7,0),
(43503,0,0,62,43503,84649,85,7,0),(45910,0,1,73,45910,85580,11,7,0),
(47176,0,0,62,47176,87924,85,7,0),(47185,0,0,62,47185,87936,85,7,0),
(47187,0,0,62,47187,87938,85,7,0),(47189,0,0,62,47189,87939,85,7,0),
(50291,0,4,61,50291,93394,11,12,1),(53590,0,1,1,53592,99513,11,7,0),
(54914,0,0,64,55057,102819,85,7,0),(54990,0,0,64,54996,102725,11,7,0),
(55141,0,0,62,55141,102972,85,7,0),(55146,0,0,62,55146,102987,85,7,0),
(55162,0,0,62,55162,103014,85,7,0),(55170,0,0,62,55170,103027,85,7,0),
(55809,0,0,64,55809,113431,85,7,0),(56146,0,1,61,56146,105332,85,7,0),
(56151,0,1,61,56146,105332,85,7,0),(56278,0,1,61,56146,105332,85,7,0),
(56279,0,1,61,56146,105332,85,7,0),(56280,0,1,61,56146,105332,85,7,0),
(56281,0,1,61,56146,105332,85,7,0),(56347,0,0,10,56347,106032,11,7,0),
(56347,0,1,10,56347,106032,11,7,0),(57457,0,6,61,58238,110437,11,12,1),
(58242,0,6,61,58238,110437,11,12,1),(58719,0,1,61,58719,132414,85,7,0),
(59272,0,0,19,60982,118199,85,7,0),(59392,0,0,62,59392,114210,85,7,0),
(61381,0,1,61,61381,119636,11,7,0),(61417,0,1,61,61381,119636,11,7,0),
(62202,0,1,62,62538,122070,85,7,0),(66220,0,0,10,66220,131345,85,7,0),
(66220,0,1,10,66220,131345,85,7,0),(66283,0,2,61,66283,130992,85,7,0),
(66396,0,2,61,66396,130623,85,7,0),(68108,0,1,61,68108,134618,85,7,0),
(68526,0,0,62,68952,135854,85,7,0),(68526,0,1,61,68524,135021,85,7,0),
(68531,0,0,64,68530,135069,85,7,0),(196439,1,1,61,50046,66127,85,7,0),
(202108,1,0,70,38318,71662,11,7,0),(202954,1,0,64,40544,75615,11,7,0),
(209780,1,0,70,55889,104902,85,7,0),(212182,1,0,70,55379,103576,85,7,0),
(212183,1,0,70,55383,103581,85,7,0),(212184,1,0,70,55388,103593,85,7,0),
(212186,1,0,70,55392,103596,85,7,0),(3964400,9,0,0,39719,74260,11,7,0);

START TRANSACTION;

SET @fifty_quest_credits_backup_ok :=
(
    SELECT COUNT(*) = 50
    FROM `_backup_smart_scripts_fifty_quest_credits_20260727`
);

DELETE `s`
FROM `smart_scripts` AS `s`
INNER JOIN `_tmp_fifty_quest_credit_map_20260727` AS `m`
    ON  `m`.`entryorguid` = `s`.`entryorguid`
    AND `m`.`source_type` = `s`.`source_type`
    AND `m`.`id` = `s`.`id`
    AND `m`.`event_type` = `s`.`event_type`
    AND `m`.`target_type` = `s`.`target_type`
    AND `m`.`target_param1` = `s`.`target_param1`
WHERE @fifty_quest_credits_backup_ok = 1
  AND
  (
      (`s`.`action_type` = `m`.`new_action` AND `s`.`action_param1` = `m`.`spell_id`)
      OR
      (`s`.`action_type` = 33 AND `s`.`action_param1` = `m`.`old_credit`)
  );

INSERT INTO `smart_scripts`
SELECT `b`.*
FROM `_backup_smart_scripts_fifty_quest_credits_20260727` AS `b`
WHERE @fifty_quest_credits_backup_ok = 1;

COMMIT;

DROP TEMPORARY TABLE `_tmp_fifty_quest_credit_map_20260727`;
