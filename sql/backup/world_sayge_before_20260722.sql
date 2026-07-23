-- Exact rollback for
-- 2026_07_22_08_world_restore_sayge_cpp_script.sql.

START TRANSACTION;

SET @sayge_backup_ok :=
(
    (SELECT COUNT(*) = 1
     FROM `_backup_creature_template_sayge_20260722`
     WHERE `entry` = 14822)
    AND
    (SELECT COUNT(*) = 15
     FROM `_backup_smart_scripts_sayge_20260722`
     WHERE `entryorguid` = 14822 AND `source_type` = 0)
    AND
    (SELECT COUNT(*) = 3
     FROM `_backup_conditions_sayge_20260722`
     WHERE `SourceTypeOrReferenceId` IN (14, 15)
       AND `SourceGroup` = 6186
       AND `ConditionTypeOrReference` = 1
       AND `ConditionValue1` = 23770)
);

UPDATE `creature_template` AS `target`
JOIN `_backup_creature_template_sayge_20260722` AS `backup`
  ON `backup`.`entry` = `target`.`entry`
SET `target`.`AIName` = `backup`.`AIName`,
    `target`.`ScriptName` = `backup`.`ScriptName`
WHERE @sayge_backup_ok = 1
  AND `target`.`entry` = 14822;

INSERT IGNORE INTO `smart_scripts`
SELECT *
FROM `_backup_smart_scripts_sayge_20260722`
WHERE @sayge_backup_ok = 1
  AND `entryorguid` = 14822
  AND `source_type` = 0;

INSERT IGNORE INTO `conditions`
SELECT *
FROM `_backup_conditions_sayge_20260722`
WHERE @sayge_backup_ok = 1
  AND `SourceTypeOrReferenceId` IN (14, 15)
  AND `SourceGroup` = 6186
  AND `ConditionTypeOrReference` = 1
  AND `ConditionValue1` = 23770;

COMMIT;
