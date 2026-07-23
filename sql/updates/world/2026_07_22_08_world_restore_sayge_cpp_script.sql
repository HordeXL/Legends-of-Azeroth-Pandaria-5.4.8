-- Restore the Build 18414 Sayge implementation already present in
-- src/server/scripts/World/npcs_special.cpp.
--
-- The active database used a newer Trinity SmartAI implementation whose
-- shared cooldown depends on spell 23770.  That spell does not exist in the
-- 5.4.8 client data, so the action and its three aura conditions are skipped.
-- SkyFire's 5.4.8 data instead assigns ScriptName = 'npc_sayge'.  The local
-- C++ script casts the eight valid fortune buffs and stores a two-hour
-- cooldown on the selected buff itself.

CREATE TABLE IF NOT EXISTS `_backup_creature_template_sayge_20260722`
LIKE `creature_template`;

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_sayge_20260722`
LIKE `smart_scripts`;

CREATE TABLE IF NOT EXISTS `_backup_conditions_sayge_20260722`
LIKE `conditions`;

INSERT IGNORE INTO `_backup_creature_template_sayge_20260722`
SELECT *
FROM `creature_template`
WHERE `entry` = 14822;

INSERT IGNORE INTO `_backup_smart_scripts_sayge_20260722`
SELECT *
FROM `smart_scripts`
WHERE `entryorguid` = 14822
  AND `source_type` = 0;

INSERT IGNORE INTO `_backup_conditions_sayge_20260722`
SELECT *
FROM `conditions`
WHERE `SourceTypeOrReferenceId` IN (14, 15)
  AND `SourceGroup` = 6186
  AND `ConditionTypeOrReference` = 1
  AND `ConditionValue1` = 23770;

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

UPDATE `creature_template`
SET `AIName` = '',
    `ScriptName` = 'npc_sayge'
WHERE @sayge_backup_ok = 1
  AND `entry` = 14822;

DELETE FROM `smart_scripts`
WHERE @sayge_backup_ok = 1
  AND `entryorguid` = 14822
  AND `source_type` = 0;

DELETE FROM `conditions`
WHERE @sayge_backup_ok = 1
  AND `SourceTypeOrReferenceId` IN (14, 15)
  AND `SourceGroup` = 6186
  AND `ConditionTypeOrReference` = 1
  AND `ConditionValue1` = 23770;

COMMIT;
