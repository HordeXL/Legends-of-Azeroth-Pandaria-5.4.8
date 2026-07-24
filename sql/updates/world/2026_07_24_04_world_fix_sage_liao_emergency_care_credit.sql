-- Quest 30794 "Emergency Care":
-- use the Build-18414 quest-credit spell instead of a manual SmartAI credit.
--
-- Item 81177 (Pandaren Healing Draught) casts spell 117472 on Sage Liao.
-- The quest objective requires one credit for creature 60720
-- (Heal Xiao Kill Credit). Build-18414 spell 117534 contains exactly one
-- SPELL_EFFECT_KILL_CREDIT2 effect for creature 60720 and no other effects.
--
-- Both Sage Liao phase entries keep their existing 117472 spell-hit event.
-- SMART_ACTION_INVOKER_CAST makes the player who used the draught cast the
-- dedicated credit spell on themselves.

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_sage_liao_emergency_care_20260724`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_sage_liao_emergency_care_20260724`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`entryorguid` IN (60694, 60785)
  AND `s`.`source_type` = 0
  AND `s`.`id` = 0
  AND `s`.`link` = 0
  AND `s`.`event_type` = 8
  AND `s`.`event_param1` = 117472
  AND `s`.`action_type` = 33
  AND `s`.`action_param1` = 60720
  AND `s`.`target_type` = 7;

START TRANSACTION;

SET @sage_liao_backup_ok :=
(
    SELECT COUNT(*) = 2
    FROM `_backup_smart_scripts_sage_liao_emergency_care_20260724`
);

UPDATE `smart_scripts`
SET `action_type` = 85,
    `action_param1` = 117534,
    `action_param2` = 1,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `target_type` = 7,
    `target_param1` = 0,
    `target_param2` = 0,
    `target_param3` = 0,
    `target_x` = 0,
    `target_y` = 0,
    `target_z` = 0,
    `target_o` = 0,
    `comment` = 'Sage Liao - player casts Emergency Care credit spell'
WHERE @sage_liao_backup_ok = 1
  AND `entryorguid` IN (60694, 60785)
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 0
  AND `event_type` = 8
  AND `event_param1` = 117472
  AND `action_type` = 33
  AND `action_param1` = 60720
  AND `target_type` = 7;

COMMIT;
