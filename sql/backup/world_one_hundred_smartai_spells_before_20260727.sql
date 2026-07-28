-- Exact, idempotent rollback for
-- 2026_07_27_08_world_fix_one_hundred_source_backed_smartai_spells.sql.

DROP TEMPORARY TABLE IF EXISTS `_tmp_one_hundred_smartai_spells_rollback_20260727`;
CREATE TEMPORARY TABLE `_tmp_one_hundred_smartai_spells_rollback_20260727`
(
    `entryorguid` INT NOT NULL,
    `source_type` TINYINT UNSIGNED NOT NULL,
    `id`          SMALLINT UNSIGNED NOT NULL,
    `event_type`  TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`entryorguid`, `source_type`, `id`, `event_type`)
);

INSERT INTO `_tmp_one_hundred_smartai_spells_rollback_20260727`
(`entryorguid`,`source_type`,`id`,`event_type`)
SELECT `entryorguid`,`source_type`,`id`,`event_type`
FROM `_backup_smart_scripts_one_hundred_spells_20260727`;

START TRANSACTION;

SET @one_hundred_smartai_backup_ok :=
(
    SELECT COUNT(*) = 100
    FROM `_backup_smart_scripts_one_hundred_spells_20260727`
);

DELETE `s`
FROM `smart_scripts` AS `s`
INNER JOIN `_tmp_one_hundred_smartai_spells_rollback_20260727` AS `m`
    ON  `m`.`entryorguid` = `s`.`entryorguid`
    AND `m`.`source_type` = `s`.`source_type`
    AND `m`.`id` = `s`.`id`
    AND `m`.`event_type` = `s`.`event_type`
WHERE @one_hundred_smartai_backup_ok = 1;

INSERT INTO `smart_scripts`
SELECT `b`.*
FROM `_backup_smart_scripts_one_hundred_spells_20260727` AS `b`
WHERE @one_hundred_smartai_backup_ok = 1;

COMMIT;

DROP TEMPORARY TABLE `_tmp_one_hundred_smartai_spells_rollback_20260727`;
