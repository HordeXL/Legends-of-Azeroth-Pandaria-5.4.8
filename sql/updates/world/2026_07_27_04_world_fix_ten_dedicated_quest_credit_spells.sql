-- Replace ten manual SmartAI quest credits with their exact Build-18414
-- credit/result spells. No quest, objective, creature, gossip, event, link,
-- target selection, timing, movement, aura cleanup, or despawn row is removed.
--
-- 35595/0  Memories of the Dead              -> 67776 Kill Credit
-- 36079/1  Calming the Kodo                  -> 68331 Kill Credit
-- 36297/2  Befriending Giants                -> 68656 Secret of Azsharite Kill Credit
-- 36297/4  Azsharite Experiment Number One   -> 68705 Experiment 01 Kill Credit
-- 36509/1  Raptor Raptor Rocket              -> 68836 Cancel Player Vehicle Aura
-- 39730/0  Elementary! - Fire                -> 74287 Aura of Fire
-- 39736/0  Elementary! - Air                 -> 74290 Aura of Air
-- 39737/0  Elementary! - Earth               -> 74288 Aura of Earth
-- 39738/0  Elementary! - Water               -> 74292 Twilight Empowerment
-- 39933/0  If You're Not Against Us...       -> 74722 Blackhorn Convinced

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_ten_quest_credits_20260727`
LIKE `smart_scripts`;

INSERT IGNORE INTO `_backup_smart_scripts_ten_quest_credits_20260727`
SELECT `s`.*
FROM `smart_scripts` AS `s`
WHERE `s`.`source_type` = 0
  AND
  (
       (`s`.`entryorguid` = 35595 AND `s`.`id` = 0 AND `s`.`action_type` = 33 AND `s`.`action_param1` = 35593)
    OR (`s`.`entryorguid` = 36079 AND `s`.`id` = 1 AND `s`.`action_type` = 33 AND `s`.`action_param1` = 36079)
    OR (`s`.`entryorguid` = 36297 AND `s`.`id` = 2 AND `s`.`action_type` = 33 AND `s`.`action_param1` = 36333)
    OR (`s`.`entryorguid` = 36297 AND `s`.`id` = 4 AND `s`.`action_type` = 33 AND `s`.`action_param1` = 36420)
    OR (`s`.`entryorguid` = 36509 AND `s`.`id` = 1 AND `s`.`action_type` = 33 AND `s`.`action_param1` = 36534)
    OR (`s`.`entryorguid` = 39730 AND `s`.`id` = 0 AND `s`.`action_type` = 33 AND `s`.`action_param1` = 39727)
    OR (`s`.`entryorguid` = 39736 AND `s`.`id` = 0 AND `s`.`action_type` = 33 AND `s`.`action_param1` = 39739)
    OR (`s`.`entryorguid` = 39737 AND `s`.`id` = 0 AND `s`.`action_type` = 33 AND `s`.`action_param1` = 39741)
    OR (`s`.`entryorguid` = 39738 AND `s`.`id` = 0 AND `s`.`action_type` = 33 AND `s`.`action_param1` = 39740)
    OR (`s`.`entryorguid` = 39933 AND `s`.`id` = 0 AND `s`.`action_type` = 33 AND `s`.`action_param1` = 40056)
  );

START TRANSACTION;

SET @ten_quest_credit_backup_ok :=
(
    SELECT COUNT(*) = 10
    FROM `_backup_smart_scripts_ten_quest_credits_20260727`
);

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 67776,
    `action_param2` = 2,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Archmage Selwyn - On Gossip Select - Cast dedicated Memories credit on player'
WHERE @ten_quest_credit_backup_ok = 1
  AND `entryorguid` = 35595
  AND `source_type` = 0
  AND `id` = 0
  AND `event_type` = 62
  AND `action_type` = 33
  AND `action_param1` = 35593
  AND `target_type` = 7;

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 68331,
    `action_param2` = 18,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Enraged Kodo KC Bunny - stored player casts dedicated calming credit on self'
WHERE @ten_quest_credit_backup_ok = 1
  AND `entryorguid` = 36079
  AND `source_type` = 0
  AND `id` = 1
  AND `event_type` = 38
  AND `event_param1` = 1
  AND `action_type` = 33
  AND `action_param1` = 36079
  AND `target_type` = 12
  AND `target_param1` = 1;

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 68656,
    `action_param2` = 2,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Gormungan - Linked To Id 1 - Cast dedicated Azsharite secret credit on player'
WHERE @ten_quest_credit_backup_ok = 1
  AND `entryorguid` = 36297
  AND `source_type` = 0
  AND `id` = 2
  AND `event_type` = 61
  AND `action_type` = 33
  AND `action_param1` = 36333
  AND `target_type` = 7;

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 68705,
    `action_param2` = 2,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Gormungan - Linked To Id 3 - Cast dedicated experiment credit on player'
WHERE @ten_quest_credit_backup_ok = 1
  AND `entryorguid` = 36297
  AND `source_type` = 0
  AND `id` = 4
  AND `event_type` = 61
  AND `action_type` = 33
  AND `action_param1` = 36420
  AND `target_type` = 7;

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 68836,
    `action_param2` = 2,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Experimental Raptor - on follow complete cast dedicated delivery result on stored player'
WHERE @ten_quest_credit_backup_ok = 1
  AND `entryorguid` = 36509
  AND `source_type` = 0
  AND `id` = 1
  AND `event_type` = 65
  AND `action_type` = 33
  AND `action_param1` = 36534
  AND `target_type` = 12
  AND `target_param1` = 1;

UPDATE `smart_scripts`
SET `action_type` = 85,
    `action_param1` = 74287,
    `action_param2` = 1,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Crucible of Fire - player casts complete fire activation spell on self'
WHERE @ten_quest_credit_backup_ok = 1
  AND `entryorguid` = 39730
  AND `source_type` = 0
  AND `id` = 0
  AND `event_type` = 64
  AND `action_type` = 33
  AND `action_param1` = 39727
  AND `target_type` = 7;

UPDATE `smart_scripts`
SET `action_type` = 85,
    `action_param1` = 74290,
    `action_param2` = 1,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Crucible of Air - player casts complete air activation spell on self'
WHERE @ten_quest_credit_backup_ok = 1
  AND `entryorguid` = 39736
  AND `source_type` = 0
  AND `id` = 0
  AND `event_type` = 64
  AND `action_type` = 33
  AND `action_param1` = 39739
  AND `target_type` = 7;

UPDATE `smart_scripts`
SET `action_type` = 85,
    `action_param1` = 74288,
    `action_param2` = 1,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Crucible of Earth - player casts complete earth activation spell on self'
WHERE @ten_quest_credit_backup_ok = 1
  AND `entryorguid` = 39737
  AND `source_type` = 0
  AND `id` = 0
  AND `event_type` = 64
  AND `action_type` = 33
  AND `action_param1` = 39741
  AND `target_type` = 7;

UPDATE `smart_scripts`
SET `action_type` = 85,
    `action_param1` = 74292,
    `action_param2` = 1,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Crucible of Water - player casts complete water activation spell on self'
WHERE @ten_quest_credit_backup_ok = 1
  AND `entryorguid` = 39738
  AND `source_type` = 0
  AND `id` = 0
  AND `event_type` = 64
  AND `action_type` = 33
  AND `action_param1` = 39740
  AND `target_type` = 7;

UPDATE `smart_scripts`
SET `action_type` = 11,
    `action_param1` = 74722,
    `action_param2` = 2,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = 'Tyrus Blackhorn - On Gossip Select - Cast dedicated convinced credit on player'
WHERE @ten_quest_credit_backup_ok = 1
  AND `entryorguid` = 39933
  AND `source_type` = 0
  AND `id` = 0
  AND `event_type` = 62
  AND `action_type` = 33
  AND `action_param1` = 40056
  AND `target_type` = 7;

COMMIT;
