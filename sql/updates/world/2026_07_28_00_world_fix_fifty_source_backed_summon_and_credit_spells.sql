-- Restore 50 exact Build-18414 SmartAI summon/result spells.
--
-- The manifest contains 30 summon actions and 20 quest-result actions.
-- It excludes incomplete ownership chains, duplicate summon+credit pairs,
-- unreferenced action lists, and result spells that would duplicate an
-- existing teleport or other linked action. No persistent row is deleted.

DROP TEMPORARY TABLE IF EXISTS `_tmp_fifty_smartai_spells_20260728`;
CREATE TEMPORARY TABLE `_tmp_fifty_smartai_spells_20260728`
(
    `entryorguid`  INT NOT NULL,
    `source_type`  TINYINT UNSIGNED NOT NULL,
    `id`           SMALLINT UNSIGNED NOT NULL,
    `event_type`   TINYINT UNSIGNED NOT NULL,
    `old_action`   TINYINT UNSIGNED NOT NULL,
    `old_param1`   INT UNSIGNED NOT NULL,
    `old_target`   TINYINT UNSIGNED NOT NULL,
    `old_tparam1`  INT UNSIGNED NOT NULL,
    `old_tparam2`  INT UNSIGNED NOT NULL,
    `spell_id`     INT UNSIGNED NOT NULL,
    `new_action`   TINYINT UNSIGNED NOT NULL,
    `new_target`   TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`entryorguid`, `source_type`, `id`, `event_type`,
                 `old_action`, `old_param1`)
);

INSERT INTO `_tmp_fifty_smartai_spells_20260728`
(`entryorguid`,`source_type`,`id`,`event_type`,`old_action`,`old_param1`,
 `old_target`,`old_tparam1`,`old_tparam2`,`spell_id`,`new_action`,`new_target`) VALUES
-- Complete quest-result spells.
(4345,0,0,6,33,23811,7,0,0,42455,11,7),
(9163,0,1,8,33,38355,7,0,0,71991,11,1),
(35526,0,0,8,33,35526,7,0,0,68944,11,1),
(36618,0,0,62,33,36625,7,0,0,69064,11,1),
(36649,0,16,6,33,36649,12,1,0,69853,11,1),
(37783,0,0,19,33,38854,7,0,0,72349,11,1),
(38214,0,8,77,33,38214,12,1,0,71364,11,1),
(38225,0,1,62,33,38225,7,0,0,73589,11,1),
(38306,0,32,61,33,38306,12,1,0,73534,11,1),
(43197,0,3,38,33,341,12,1,0,80744,11,1),
(46174,0,21,40,33,46174,12,1,0,86417,11,1),
(55267,0,0,62,33,55267,21,20,0,103181,85,7),
(55770,0,0,64,33,55770,17,0,100,114396,85,7),
(58547,0,6,61,33,58946,7,0,0,112094,11,1),
(58930,0,0,64,33,58930,7,0,0,112061,11,1),
(59703,0,0,19,33,59749,7,0,0,114935,11,1),
(68312,0,0,64,33,68312,7,0,0,134840,11,1),
(68331,0,0,64,33,68331,7,0,0,134837,11,1),
(4231700,9,1,0,33,42463,12,1,0,79227,11,1),
(6149200,9,1,0,33,54929,7,0,0,102537,85,7),
-- Creature and timed-list summon spells.
(40720,0,0,73,12,39710,7,0,0,75935,85,7),
(40723,0,0,73,12,40719,7,0,0,75943,85,7),
(42574,0,2,61,12,43047,7,0,0,80439,85,7),
(42684,0,0,19,12,42962,1,0,0,80690,11,1),
(43395,0,2,61,12,43437,7,0,0,81225,85,7),
(43443,0,1,61,12,43450,7,0,0,81243,85,7),
(43742,0,1,61,12,32851,7,0,0,64602,85,7),
(54567,0,1,19,12,59652,1,0,0,114728,11,1),
(55586,0,0,19,12,56159,1,0,0,105333,11,1),
(55942,0,0,38,12,60900,1,0,0,117973,11,1),
(56009,0,5,0,12,60685,1,0,0,117400,11,1),
(56009,0,6,61,12,60685,1,0,0,117400,11,1),
(56416,0,12,19,12,60729,1,0,0,117497,11,1),
(66207,0,1,61,12,65977,1,0,0,130152,11,1),
(66253,0,1,61,12,65899,1,0,0,130270,11,1),
(66254,0,1,61,12,65960,1,0,0,130272,11,1),
(66255,0,1,61,12,66073,1,0,0,130273,11,1),
(66256,0,1,61,12,66180,1,0,0,130274,11,1),
(66257,0,1,61,12,66149,1,0,0,130275,11,1),
(66258,0,1,61,12,66138,1,0,0,130276,11,1),
(66744,0,1,61,12,66732,1,0,0,131102,11,1),
(66854,0,0,38,12,66844,1,0,0,131365,11,1),
-- GameObject interactions: the stored event invoker performs the summon.
(184867,1,0,70,12,20021,1,0,0,36326,85,7),
(186332,1,0,70,12,23786,1,0,0,42421,85,7),
(195021,1,0,70,12,34369,1,0,0,65364,85,7),
(195188,1,1,61,12,35649,1,0,0,67845,85,7),
(203187,1,1,61,12,41112,1,0,0,77041,85,7),
(4748100,9,0,0,12,47483,1,0,0,88532,11,1),
-- The Kaliri Nest random action lists retain the GO state-change invoker.
(18158201,9,0,0,12,17034,1,0,0,29396,85,7),
(18158202,9,0,0,12,17039,1,0,0,29397,85,7);

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_fifty_spells_20260728`
LIKE `smart_scripts`;

INSERT INTO `_backup_smart_scripts_fifty_spells_20260728`
SELECT `s`.*
FROM `smart_scripts` AS `s`
INNER JOIN `_tmp_fifty_smartai_spells_20260728` AS `m`
    ON  `m`.`entryorguid` = `s`.`entryorguid`
    AND `m`.`source_type` = `s`.`source_type`
    AND `m`.`id` = `s`.`id`
    AND `m`.`event_type` = `s`.`event_type`
    AND `m`.`old_action` = `s`.`action_type`
    AND `m`.`old_param1` = `s`.`action_param1`
    AND `m`.`old_target` = `s`.`target_type`
    AND `m`.`old_tparam1` = `s`.`target_param1`
    AND `m`.`old_tparam2` = `s`.`target_param2`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_smart_scripts_fifty_spells_20260728` AS `b`
    WHERE `b`.`entryorguid` = `s`.`entryorguid`
      AND `b`.`source_type` = `s`.`source_type`
      AND `b`.`id` = `s`.`id`
      AND `b`.`event_type` = `s`.`event_type`
      AND `b`.`action_type` = `s`.`action_type`
      AND `b`.`action_param1` = `s`.`action_param1`
);

START TRANSACTION;

SET @fifty_smartai_spells_backup_ok :=
(
    SELECT COUNT(*) = 50
    FROM `_backup_smart_scripts_fifty_spells_20260728`
);

UPDATE `smart_scripts` AS `s`
INNER JOIN `_tmp_fifty_smartai_spells_20260728` AS `m`
    ON  `m`.`entryorguid` = `s`.`entryorguid`
    AND `m`.`source_type` = `s`.`source_type`
    AND `m`.`id` = `s`.`id`
    AND `m`.`event_type` = `s`.`event_type`
    AND `m`.`old_action` = `s`.`action_type`
    AND `m`.`old_param1` = `s`.`action_param1`
    AND `m`.`old_target` = `s`.`target_type`
    AND `m`.`old_tparam1` = `s`.`target_param1`
    AND `m`.`old_tparam2` = `s`.`target_param2`
SET `s`.`action_type` = `m`.`new_action`,
    `s`.`action_param1` = `m`.`spell_id`,
    `s`.`action_param2` = 2,
    `s`.`action_param3` = 0,
    `s`.`action_param4` = 0,
    `s`.`action_param5` = 0,
    `s`.`action_param6` = 0,
    `s`.`target_type` = `m`.`new_target`,
    `s`.`target_param1` = 0,
    `s`.`target_param2` = 0,
    `s`.`target_param3` = 0,
    `s`.`target_x` = 0,
    `s`.`target_y` = 0,
    `s`.`target_z` = 0,
    `s`.`target_o` = 0,
    `s`.`comment` = CONCAT(LEFT(`s`.`comment`, 185),
        ' - Cast source-backed spell ', `m`.`spell_id`)
WHERE @fifty_smartai_spells_backup_ok = 1;

COMMIT;

DROP TEMPORARY TABLE `_tmp_fifty_smartai_spells_20260728`;
