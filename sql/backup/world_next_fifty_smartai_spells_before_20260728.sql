-- Exact, idempotent rollback for
-- 2026_07_28_01_world_fix_next_fifty_source_backed_smartai_spells.sql.

DROP TEMPORARY TABLE IF EXISTS `_tmp_next_fifty_smartai_spells_rollback_20260728`;
CREATE TEMPORARY TABLE `_tmp_next_fifty_smartai_spells_rollback_20260728`
(
    `entryorguid` INT NOT NULL,
    `source_type` TINYINT UNSIGNED NOT NULL,
    `id` SMALLINT UNSIGNED NOT NULL,
    `event_type` TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`entryorguid`, `source_type`, `id`, `event_type`)
);

INSERT INTO `_tmp_next_fifty_smartai_spells_rollback_20260728`
(`entryorguid`,`source_type`,`id`,`event_type`)
SELECT `entryorguid`,`source_type`,`id`,`event_type`
FROM `_backup_smart_scripts_next_fifty_spells_20260728`;

START TRANSACTION;

SET @next_fifty_smartai_spells_backup_ok :=
(
    SELECT COUNT(*) = 50
    FROM `_backup_smart_scripts_next_fifty_spells_20260728`
);

DELETE `s`
FROM `smart_scripts` AS `s`
INNER JOIN `_tmp_next_fifty_smartai_spells_rollback_20260728` AS `m`
    ON  `m`.`entryorguid` = `s`.`entryorguid`
    AND `m`.`source_type` = `s`.`source_type`
    AND `m`.`id` = `s`.`id`
    AND `m`.`event_type` = `s`.`event_type`
WHERE @next_fifty_smartai_spells_backup_ok = 1;

INSERT INTO `smart_scripts`
SELECT `b`.*
FROM `_backup_smart_scripts_next_fifty_spells_20260728` AS `b`
WHERE @next_fifty_smartai_spells_backup_ok = 1;

COMMIT;

DROP TEMPORARY TABLE `_tmp_next_fifty_smartai_spells_rollback_20260728`;
