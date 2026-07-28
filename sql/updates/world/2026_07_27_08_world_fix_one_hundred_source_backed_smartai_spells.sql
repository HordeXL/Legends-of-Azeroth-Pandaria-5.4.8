-- Restore 100 exact Build-18414 result/summon spells in place of manual
-- SmartAI summon and quest-credit actions.
--
-- Selection rules:
--   * every spell and effect exists in the local Build-18414 client data;
--   * the event source, caster, implicit target and surrounding linked actions
--     were checked;
--   * summon spells that would duplicate a separate adjacent summon were
--     excluded;
--   * no SmartAI, quest, creature, gameobject or condition row is deleted.

DROP TEMPORARY TABLE IF EXISTS `_tmp_one_hundred_smartai_spells_20260727`;
CREATE TEMPORARY TABLE `_tmp_one_hundred_smartai_spells_20260727`
(
    `entryorguid`   INT NOT NULL,
    `source_type`   TINYINT UNSIGNED NOT NULL,
    `id`            SMALLINT UNSIGNED NOT NULL,
    `event_type`    TINYINT UNSIGNED NOT NULL,
    `old_action`    TINYINT UNSIGNED NOT NULL,
    `old_param1`    INT UNSIGNED NOT NULL,
    `spell_id`      INT UNSIGNED NOT NULL,
    `new_action`    TINYINT UNSIGNED NOT NULL,
    `new_target`    TINYINT UNSIGNED NOT NULL,
    `new_tparam1`   INT UNSIGNED NOT NULL,
    PRIMARY KEY (`entryorguid`, `source_type`, `id`, `event_type`, `old_action`, `old_param1`)
);

INSERT INTO `_tmp_one_hundred_smartai_spells_20260727`
(`entryorguid`,`source_type`,`id`,`event_type`,`old_action`,`old_param1`,
 `spell_id`,`new_action`,`new_target`,`new_tparam1`) VALUES
-- Personal, area and summoner/passenger quest-result spells.
(33374,0,0,73,33,33374,62890,85,7,0),
(36142,0,0,1,33,36142,68414,11,1,0),
(37108,0,0,1,33,37109,70007,11,1,0),
(37173,0,0,1,33,37110,70008,11,1,0),
(37174,0,0,1,33,37111,70009,11,1,0),
(38855,0,0,6,33,38868,73060,11,1,0),
(41578,0,1,38,33,42169,77792,11,1,0),
(42479,0,0,8,33,45083,84008,85,7,0),
(42505,0,0,1,33,42463,79227,11,1,0),
(42781,0,0,8,33,45083,84008,85,7,0),
(42788,0,0,1,33,42788,84399,11,1,0),
(43372,0,1,6,33,43372,96188,11,1,0),
(43437,0,1,23,33,43370,81223,11,1,0),
(43591,0,1,65,33,43597,81360,11,1,0),
(43727,0,0,19,33,43729,81779,85,7,0),
(43932,0,3,2,33,45115,84217,11,1,0),
(44057,0,0,73,33,44054,82457,85,7,0),
(44352,0,0,1,33,44352,84397,11,1,0),
(44353,0,0,1,33,44353,84398,11,1,0),
(45088,0,1,8,33,45091,84170,11,1,0),
(46654,0,2,59,33,46654,87446,85,7,0),
(47274,0,0,73,33,47252,94940,85,7,0),
(47281,0,4,38,33,47279,88154,11,1,0),
(47333,0,4,38,33,47381,88320,11,1,0),
(52201,0,17,61,33,52360,96846,11,1,0),
(56336,0,0,64,33,56336,106204,85,7,0),
(56340,0,0,64,33,56340,106189,85,7,0),
(56477,0,0,64,33,56477,106190,85,7,0),
(56478,0,0,64,33,56478,106191,85,7,0),
(58646,0,2,64,33,70454,139916,85,7,0),
(59509,0,0,10,33,59371,115897,85,7,0),
(59509,0,1,10,33,59371,115897,85,7,0),
(59986,0,11,61,33,59947,115443,11,1,0),
(60008,0,1,61,33,60008,115567,85,7,0),
(60094,0,2,61,33,60022,115952,85,7,0),
(60899,0,1,61,33,60899,117974,85,7,0),
(61693,0,0,19,33,59319,114067,85,7,0),
(64848,0,1,61,33,64848,126811,85,7,0),
(64853,0,1,61,33,64853,126811,85,7,0),
(65910,0,2,61,33,65910,130858,85,7,0),
(67662,0,0,64,33,69543,137262,85,7,0),
(67994,0,0,64,33,69543,137262,85,7,0),
-- Direct creature summons with caster-equivalent destinations.
(38214,0,0,11,12,38213,71358,11,1,0),
(38214,0,1,61,12,38213,71358,11,1,0),
(38214,0,2,61,12,38213,71358,11,1,0),
(38214,0,3,61,12,38213,71358,11,1,0),
(38214,0,4,61,12,38213,71358,11,1,0),
(38214,0,6,61,12,38213,71358,11,1,0),
(39081,0,1,6,12,39082,73441,11,1,0),
(39446,0,1,6,12,39622,74077,11,1,0),
(39446,0,2,6,12,39627,74078,11,1,0),
(39974,0,1,61,12,40093,74760,11,1,0),
(40875,0,6,2,12,41077,76746,11,1,0),
(40876,0,6,2,12,41083,76749,11,1,0),
(42681,0,0,38,12,42757,79699,11,1,0),
(42682,0,0,38,12,42747,79657,11,1,0),
(45100,0,0,54,12,45099,82043,11,1,0),
(47445,0,1,61,12,47488,88542,11,1,0),
(52349,0,1,6,12,52315,96751,11,1,0),
(52349,0,4,61,12,52313,96747,11,1,0),
-- GameObject event invokers cast the complete player-owned spell.
(202954,1,1,64,12,40551,75625,85,7,0),
(205061,1,0,64,33,39393,73888,85,7,0),
(209835,1,0,70,33,60967,105456,85,7,0),
(212969,1,0,64,33,63344,123729,85,7,0),
-- Timed action lists owned by creatures, vehicles or an interacting GO.
(1712700,9,1,0,12,47001,87534,11,1,0),
(1712700,9,13,0,33,47541,88647,11,1,0),
(2120000,9,13,0,33,45769,85376,11,1,0),
(2931902,9,3,0,12,33011,62116,11,1,0),
(2932702,9,3,0,12,33010,62108,11,1,0),
(4670700,9,4,0,33,46737,87073,11,1,0),
(4670700,9,9,0,33,46738,87074,11,1,0),
(4670700,9,14,0,33,46739,87075,11,1,0),
(4670700,9,19,0,33,46740,87076,11,1,0),
(4724900,9,38,0,33,47249,88127,11,1,0),
(5113901,9,0,0,12,35811,68058,11,1,0),
(5113901,9,1,0,12,35750,67913,11,1,0),
(5113901,9,2,0,12,35811,68058,11,1,0),
(5113901,9,3,0,12,35750,67913,11,1,0),
(5113901,9,4,0,12,35811,68058,11,1,0),
(5113901,9,5,0,12,35752,67904,11,1,0),
(5113902,9,0,0,12,35811,68058,11,1,0),
(5113902,9,1,0,12,35750,67913,11,1,0),
(5113902,9,2,0,12,35811,68058,11,1,0),
(5113902,9,3,0,12,35750,67913,11,1,0),
(5113902,9,4,0,12,35811,68058,11,1,0),
(5113902,9,5,0,12,35752,67904,11,1,0),
(5113903,9,0,0,12,35811,68058,11,1,0),
(5113903,9,1,0,12,35750,67913,11,1,0),
(5113903,9,2,0,12,35811,68058,11,1,0),
(5113903,9,3,0,12,35750,67913,11,1,0),
(5113903,9,4,0,12,35811,68058,11,1,0),
(5113903,9,5,0,12,35752,67904,11,1,0),
(5113904,9,0,0,12,35811,68058,11,1,0),
(5113904,9,1,0,12,35750,67913,11,1,0),
(5113904,9,2,0,12,35811,68058,11,1,0),
(5113904,9,3,0,12,35750,67913,11,1,0),
(5113904,9,4,0,12,35811,68058,11,1,0),
(5113904,9,5,0,12,35752,67904,11,1,0),
(5998600,9,1,0,33,59946,115442,11,1,0),
(20320800,9,0,0,12,41224,77308,85,7,0);

CREATE TABLE IF NOT EXISTS `_backup_smart_scripts_one_hundred_spells_20260727`
LIKE `smart_scripts`;

INSERT INTO `_backup_smart_scripts_one_hundred_spells_20260727`
SELECT `s`.*
FROM `smart_scripts` AS `s`
INNER JOIN `_tmp_one_hundred_smartai_spells_20260727` AS `m`
    ON  `m`.`entryorguid` = `s`.`entryorguid`
    AND `m`.`source_type` = `s`.`source_type`
    AND `m`.`id` = `s`.`id`
    AND `m`.`event_type` = `s`.`event_type`
    AND `m`.`old_action` = `s`.`action_type`
    AND `m`.`old_param1` = `s`.`action_param1`
WHERE NOT EXISTS
(
    SELECT 1
    FROM `_backup_smart_scripts_one_hundred_spells_20260727` AS `b`
    WHERE `b`.`entryorguid` = `s`.`entryorguid`
      AND `b`.`source_type` = `s`.`source_type`
      AND `b`.`id` = `s`.`id`
      AND `b`.`event_type` = `s`.`event_type`
      AND `b`.`action_type` = `s`.`action_type`
      AND `b`.`action_param1` = `s`.`action_param1`
);

START TRANSACTION;

SET @one_hundred_smartai_backup_ok :=
(
    SELECT COUNT(*) = 100
    FROM `_backup_smart_scripts_one_hundred_spells_20260727`
);

UPDATE `smart_scripts` AS `s`
INNER JOIN `_tmp_one_hundred_smartai_spells_20260727` AS `m`
    ON  `m`.`entryorguid` = `s`.`entryorguid`
    AND `m`.`source_type` = `s`.`source_type`
    AND `m`.`id` = `s`.`id`
    AND `m`.`event_type` = `s`.`event_type`
    AND `m`.`old_action` = `s`.`action_type`
    AND `m`.`old_param1` = `s`.`action_param1`
SET `s`.`action_type` = `m`.`new_action`,
    `s`.`action_param1` = `m`.`spell_id`,
    `s`.`action_param2` = 2,
    `s`.`action_param3` = 0,
    `s`.`action_param4` = 0,
    `s`.`action_param5` = 0,
    `s`.`action_param6` = 0,
    `s`.`target_type` = `m`.`new_target`,
    `s`.`target_param1` = `m`.`new_tparam1`,
    `s`.`target_param2` = 0,
    `s`.`target_param3` = 0,
    `s`.`target_x` = 0,
    `s`.`target_y` = 0,
    `s`.`target_z` = 0,
    `s`.`target_o` = 0,
    `s`.`comment` = CONCAT(LEFT(`s`.`comment`, 185),
        ' - Cast source-backed spell ', `m`.`spell_id`)
WHERE @one_hundred_smartai_backup_ok = 1;

COMMIT;

DROP TEMPORARY TABLE `_tmp_one_hundred_smartai_spells_20260727`;
