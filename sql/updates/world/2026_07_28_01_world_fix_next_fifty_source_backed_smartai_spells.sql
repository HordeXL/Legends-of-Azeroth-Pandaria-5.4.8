-- Restore the next 50 exact Build-18414 SmartAI summon/result spells.
--
-- The manifest contains 29 summon actions and 21 quest-result actions.
-- It excludes rows with unresolved ownership, group-credit loss, duplicate
-- summon/result effects, absent Build-18414 spells, unreferenced action lists,
-- and incompatible absolute destinations. No persistent row is deleted.

DROP TEMPORARY TABLE IF EXISTS `_tmp_next_fifty_smartai_spells_20260728`;
CREATE TEMPORARY TABLE `_tmp_next_fifty_smartai_spells_20260728`
(
    `entryorguid` INT NOT NULL,
    `source_type` TINYINT UNSIGNED NOT NULL,
    `id` SMALLINT UNSIGNED NOT NULL,
    `event_type` TINYINT UNSIGNED NOT NULL,
    `old_action` TINYINT UNSIGNED NOT NULL,
    `old_param1` INT UNSIGNED NOT NULL,
    `old_param2` INT UNSIGNED NOT NULL,
    `old_param3` INT UNSIGNED NOT NULL,
    `old_target` TINYINT UNSIGNED NOT NULL,
    `old_tparam1` INT UNSIGNED NOT NULL,
    `old_tparam2` INT UNSIGNED NOT NULL,
    `old_tparam3` INT UNSIGNED NOT NULL,
    `spell_id` INT UNSIGNED NOT NULL,
    `new_action` TINYINT UNSIGNED NOT NULL,
    `new_param3` INT UNSIGNED NOT NULL,
    `new_param4` INT UNSIGNED NOT NULL,
    `new_param5` INT UNSIGNED NOT NULL,
    `new_param6` INT UNSIGNED NOT NULL,
    `new_target` TINYINT UNSIGNED NOT NULL,
    `new_tparam1` INT UNSIGNED NOT NULL,
    `new_tparam2` INT UNSIGNED NOT NULL,
    `new_tparam3` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`entryorguid`, `source_type`, `id`, `event_type`,
                 `old_action`, `old_param1`)
);

INSERT INTO `_tmp_next_fifty_smartai_spells_20260728`
(`entryorguid`,`source_type`,`id`,`event_type`,`old_action`,
 `old_param1`,`old_param2`,`old_param3`,
 `old_target`,`old_tparam1`,`old_tparam2`,`old_tparam3`,
 `spell_id`,`new_action`,`new_param3`,`new_param4`,`new_param5`,`new_param6`,
 `new_target`,`new_tparam1`,`new_tparam2`,`new_tparam3`) VALUES
-- Complete quest-result spells.
(33421,0,0,62,33,33507,0,0,7,0,0,0,63393,85,0,0,0,0,7,0,0,0),
(37667,0,3,1,33,37668,0,0,17,0,50,0,70310,11,0,0,0,0,1,0,0,0),
(36227,0,0,73,33,36232,0,0,7,0,0,0,97214,85,0,0,0,0,7,0,0,0),
(40223,0,2,8,33,40339,0,0,7,0,0,0,75385,11,0,0,0,0,23,0,0,0),
(44482,0,1,6,33,44777,0,0,7,0,0,0,83484,11,0,0,0,0,1,0,0,0),
(45878,0,5,38,33,46002,0,0,12,1,0,0,85750,11,0,0,0,0,12,1,0,0),
(47662,0,2,5,33,47752,0,0,12,1,0,0,88894,11,0,0,0,0,12,1,0,0),
(47662,0,3,5,33,47752,0,0,12,1,0,0,88894,11,0,0,0,0,12,1,0,0),
-- Pei-Zhi's periodic result has no event invoker. The same single closest
-- player selected by the old action becomes both cross-caster and target.
(55480,0,0,60,33,55480,0,0,18,10,0,0,103975,86,18,10,0,0,18,10,0,0),
(56206,0,3,2,33,56206,0,0,7,0,0,0,123174,11,0,0,0,0,7,0,0,0),
(56209,0,3,2,33,56209,0,0,7,0,0,0,123176,11,0,0,0,0,7,0,0,0),
(56210,0,3,2,33,56210,0,0,7,0,0,0,123178,11,0,0,0,0,7,0,0,0),
(202766,1,0,70,33,39996,0,0,7,0,0,0,75538,85,0,0,0,0,7,0,0,0),
(213304,1,0,70,33,63698,0,0,7,0,0,0,124343,85,0,0,0,0,7,0,0,0),
(213305,1,0,70,33,63699,0,0,7,0,0,0,124372,85,0,0,0,0,7,0,0,0),
(213306,1,0,70,33,63700,0,0,7,0,0,0,124373,85,0,0,0,0,7,0,0,0),
(213307,1,0,70,33,63702,0,0,7,0,0,0,124395,85,0,0,0,0,7,0,0,0),
(213308,1,0,70,33,63703,0,0,7,0,0,0,124396,85,0,0,0,0,7,0,0,0),
(213309,1,0,70,33,63701,0,0,7,0,0,0,124375,85,0,0,0,0,7,0,0,0),
(213310,1,0,70,33,63704,0,0,7,0,0,0,124397,85,0,0,0,0,7,0,0,0),
(213311,1,0,70,33,63705,0,0,7,0,0,0,124398,85,0,0,0,0,7,0,0,0),
-- Creature and linked summon spells.
(36931,0,15,61,12,37062,6,10000,8,0,0,0,69827,11,0,0,0,0,1,0,0,0),
(36931,0,16,61,12,37062,6,10000,8,0,0,0,69827,11,0,0,0,0,1,0,0,0),
(37951,0,1,61,12,37988,8,0,8,0,0,0,70892,11,0,0,0,0,1,0,0,0),
(37951,0,3,61,12,37988,8,0,8,0,0,0,70892,11,0,0,0,0,1,0,0,0),
(37951,0,5,61,12,37988,8,0,8,0,0,0,70892,11,0,0,0,0,1,0,0,0),
(37951,0,7,61,12,37988,8,0,8,0,0,0,70892,11,0,0,0,0,1,0,0,0),
(37951,0,9,61,12,37988,8,0,8,0,0,0,70892,11,0,0,0,0,1,0,0,0),
(37951,0,11,61,12,37988,8,0,8,0,0,0,70892,11,0,0,0,0,1,0,0,0),
(37951,0,13,61,12,37988,8,0,8,0,0,0,70892,11,0,0,0,0,1,0,0,0),
(37951,0,15,61,12,37988,8,0,8,0,0,0,70892,11,0,0,0,0,1,0,0,0),
(37951,0,17,61,12,37988,8,0,8,0,0,0,70892,11,0,0,0,0,1,0,0,0),
(40726,0,2,61,12,40663,8,0,8,0,0,0,75859,11,0,0,0,0,1,0,0,0),
(40726,0,6,61,12,40663,8,0,8,0,0,0,75859,11,0,0,0,0,1,0,0,0),
(40727,0,2,61,12,40663,8,0,8,0,0,0,75859,11,0,0,0,0,1,0,0,0),
(40727,0,6,61,12,40663,8,0,8,0,0,0,75859,11,0,0,0,0,1,0,0,0),
-- The gossip invoker casts the DB-positioned portal and receives its aura.
(49635,0,2,61,12,49638,3,30000,8,0,0,0,92590,85,0,0,0,0,7,0,0,0),
(55021,0,1,61,12,57638,8,0,8,0,0,0,108808,11,0,0,0,0,1,0,0,0),
(55478,0,0,20,12,57667,8,0,8,0,0,0,108827,11,0,0,0,0,1,0,0,0),
(55585,0,1,61,12,57670,8,0,8,0,0,0,108845,11,0,0,0,0,1,0,0,0),
(55585,0,8,61,12,57692,8,0,8,0,0,0,108857,11,0,0,0,0,1,0,0,0),
(55595,0,2,61,12,64532,3,30000,8,0,0,0,126043,11,0,0,0,0,1,0,0,0),
(56416,0,13,61,12,60741,8,0,8,0,0,0,117597,11,0,0,0,0,1,0,0,0),
-- Timed-list summons with complete dedicated DB-position spells.
(3911700,9,11,0,12,38983,3,1000,8,0,0,0,73184,11,0,0,0,0,1,0,0,0),
(3911700,9,12,0,12,38981,1,60000,8,0,0,0,73180,11,0,0,0,0,1,0,0,0),
(4748800,9,1,0,12,47444,8,0,8,0,0,0,88559,11,0,0,0,0,1,0,0,0),
(4748800,9,2,0,12,47443,8,0,8,0,0,0,88560,11,0,0,0,0,1,0,0,0),
(4748800,9,3,0,12,47442,8,0,8,0,0,0,88562,11,0,0,0,0,1,0,0,0),
(1712700,9,2,0,12,46986,3,50000,8,0,0,0,87536,11,0,0,0,0,1,0,0,0),
-- The quest-accept invoker casts the player-side shark summon and aura.
(60674,0,0,19,12,60408,1,100000,8,0,0,0,124720,85,0,0,0,0,7,0,0,0);

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_next_fifty_spells_20260728`
LIKE `smart_scripts`;

INSERT INTO `_backup_smart_scripts_next_fifty_spells_20260728`
SELECT `s`.*
FROM `smart_scripts` AS `s`
INNER JOIN `_tmp_next_fifty_smartai_spells_20260728` AS `m`
    ON  `m`.`entryorguid` = `s`.`entryorguid`
    AND `m`.`source_type` = `s`.`source_type`
    AND `m`.`id` = `s`.`id`
    AND `m`.`event_type` = `s`.`event_type`
    AND `m`.`old_action` = `s`.`action_type`
    AND `m`.`old_param1` = `s`.`action_param1`
    AND `m`.`old_param2` = `s`.`action_param2`
    AND `m`.`old_param3` = `s`.`action_param3`
    AND `m`.`old_target` = `s`.`target_type`
    AND `m`.`old_tparam1` = `s`.`target_param1`
    AND `m`.`old_tparam2` = `s`.`target_param2`
    AND `m`.`old_tparam3` = `s`.`target_param3`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_smart_scripts_next_fifty_spells_20260728` AS `b`
    WHERE `b`.`entryorguid` = `s`.`entryorguid`
      AND `b`.`source_type` = `s`.`source_type`
      AND `b`.`id` = `s`.`id`
      AND `b`.`event_type` = `s`.`event_type`
      AND `b`.`action_type` = `s`.`action_type`
      AND `b`.`action_param1` = `s`.`action_param1`
);

START TRANSACTION;

SET @next_fifty_smartai_spells_backup_ok :=
(
    SELECT COUNT(*) = 50
    FROM `_backup_smart_scripts_next_fifty_spells_20260728`
);

UPDATE `smart_scripts` AS `s`
INNER JOIN `_tmp_next_fifty_smartai_spells_20260728` AS `m`
    ON  `m`.`entryorguid` = `s`.`entryorguid`
    AND `m`.`source_type` = `s`.`source_type`
    AND `m`.`id` = `s`.`id`
    AND `m`.`event_type` = `s`.`event_type`
    AND `m`.`old_action` = `s`.`action_type`
    AND `m`.`old_param1` = `s`.`action_param1`
    AND `m`.`old_param2` = `s`.`action_param2`
    AND `m`.`old_param3` = `s`.`action_param3`
    AND `m`.`old_target` = `s`.`target_type`
    AND `m`.`old_tparam1` = `s`.`target_param1`
    AND `m`.`old_tparam2` = `s`.`target_param2`
    AND `m`.`old_tparam3` = `s`.`target_param3`
SET `s`.`action_type` = `m`.`new_action`,
    `s`.`action_param1` = `m`.`spell_id`,
    `s`.`action_param2` = 2,
    `s`.`action_param3` = `m`.`new_param3`,
    `s`.`action_param4` = `m`.`new_param4`,
    `s`.`action_param5` = `m`.`new_param5`,
    `s`.`action_param6` = `m`.`new_param6`,
    `s`.`target_type` = `m`.`new_target`,
    `s`.`target_param1` = `m`.`new_tparam1`,
    `s`.`target_param2` = `m`.`new_tparam2`,
    `s`.`target_param3` = `m`.`new_tparam3`,
    `s`.`target_x` = 0,
    `s`.`target_y` = 0,
    `s`.`target_z` = 0,
    `s`.`target_o` = 0,
    `s`.`comment` = CONCAT(LEFT(`s`.`comment`, 185),
        ' - Cast source-backed spell ', `m`.`spell_id`)
WHERE @next_fifty_smartai_spells_backup_ok = 1;

COMMIT;

DROP TEMPORARY TABLE `_tmp_next_fifty_smartai_spells_20260728`;
