-- Exact, idempotent rollback for
-- 2026_07_28_00_world_fix_fifty_source_backed_summon_and_credit_spells.sql.

DROP TEMPORARY TABLE IF EXISTS `_tmp_fifty_smartai_spells_rollback_20260728`;
CREATE TEMPORARY TABLE `_tmp_fifty_smartai_spells_rollback_20260728`
(
    `entryorguid` INT NOT NULL,
    `source_type` TINYINT UNSIGNED NOT NULL,
    `id`          SMALLINT UNSIGNED NOT NULL,
    `event_type`  TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`entryorguid`, `source_type`, `id`, `event_type`)
);

INSERT INTO `_tmp_fifty_smartai_spells_rollback_20260728`
(`entryorguid`,`source_type`,`id`,`event_type`)
SELECT `entryorguid`,`source_type`,`id`,`event_type`
FROM `_backup_smart_scripts_fifty_spells_20260728`;

START TRANSACTION;

SET @fifty_smartai_spells_backup_ok :=
(
    SELECT COUNT(*) = 50
    FROM `_backup_smart_scripts_fifty_spells_20260728`
);

DELETE `s`
FROM `smart_scripts` AS `s`
INNER JOIN `_tmp_fifty_smartai_spells_rollback_20260728` AS `m`
    ON  `m`.`entryorguid` = `s`.`entryorguid`
    AND `m`.`source_type` = `s`.`source_type`
    AND `m`.`id` = `s`.`id`
    AND `m`.`event_type` = `s`.`event_type`
WHERE @fifty_smartai_spells_backup_ok = 1;

INSERT INTO `smart_scripts`
SELECT `b`.*
FROM `_backup_smart_scripts_fifty_spells_20260728` AS `b`
WHERE @fifty_smartai_spells_backup_ok = 1;

COMMIT;

DROP TEMPORARY TABLE `_tmp_fifty_smartai_spells_rollback_20260728`;
