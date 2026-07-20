-- Exact rollback for quest 31765 before the Powder Round repair.
-- Run only against the corrected state produced by update 2026_07_20_05.

START TRANSACTION;

SET @corrected_objectives := (
    SELECT COUNT(*) FROM `quest_objective`
    WHERE (`questId` = 31765 AND `id` = 269073 AND `index` = 0 AND `type` = 0
           AND `objectId` = 66200 AND `amount` = 80 AND `flags` = 0
           AND `description` = 'Thunder Hold troops slain')
       OR (`questId` = 31765 AND `id` = 269074 AND `index` = 1 AND `type` = 0
           AND `objectId` = 66203 AND `amount` = 9 AND `flags` = 0
           AND `description` = 'Thunder Hold cannons destroyed')
);
SET @spell_rows := (SELECT COUNT(*) FROM `spell_scripts` WHERE `id` = 130973);
SET @smart_rows := (SELECT COUNT(*) FROM `smart_scripts`
                    WHERE `entryorguid` = 55135 AND `source_type` = 0 AND `id` IN (0, 1));
SET @can_rollback := (@corrected_objectives = 2 AND @spell_rows = 0 AND @smart_rows = 0);

UPDATE `quest_objective`
SET `amount` = 1
WHERE @can_rollback AND `questId` = 31765
  AND ((`id` = 269073 AND `index` = 0 AND `type` = 0 AND `objectId` = 66200
        AND `amount` = 80 AND `flags` = 0 AND `description` = 'Thunder Hold troops slain')
    OR (`id` = 269074 AND `index` = 1 AND `type` = 0 AND `objectId` = 66203
        AND `amount` = 9 AND `flags` = 0 AND `description` = 'Thunder Hold cannons destroyed'));

INSERT INTO `spell_scripts`
    (`id`,`effIndex`,`delay`,`command`,`datalong`,`datalong2`,`dataint`,`x`,`y`,`z`,`o`)
SELECT 130973,0,0,8,66200,0,0,0,0,0,0 FROM DUAL WHERE @can_rollback
UNION ALL
SELECT 130973,0,0,8,66203,0,0,0,0,0,0 FROM DUAL WHERE @can_rollback;

INSERT INTO `smart_scripts`
    (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
     `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,
     `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
     `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,
     `target_x`,`target_y`,`target_z`,`target_o`,`comment`)
SELECT 55135,0,0,1,19,0,100,0,31765,0,0,0,0,33,66200,0,0,0,0,0,7,0,0,0,0,0,0,0,0,'General Nazgrim'
FROM DUAL WHERE @can_rollback
UNION ALL
SELECT 55135,0,1,0,61,0,100,0,0,0,0,0,0,33,66203,0,0,0,0,0,7,0,0,0,0,0,0,0,0,'General Nazgrim'
FROM DUAL WHERE @can_rollback;

COMMIT;
