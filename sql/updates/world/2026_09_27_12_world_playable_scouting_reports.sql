-- Playable Scouting Reports: Gorrok, Riko and Shokia.
-- Requires the matching rebuilt server and AddSC_scouting_reports registration.
START TRANSACTION;
UPDATE `creature_template`
SET `npcflag`=`npcflag` | 3,`unit_flags`=`unit_flags` | 512,
    `AIName`='',`ScriptName`='npc_jade_forest_scouting_report'
WHERE `entry` IN (55647,55648);
UPDATE `creature` SET `unit_flags`=`unit_flags` | 512 WHERE `id` IN (55647,55648);

UPDATE `creature_template`
SET `VehicleId`=238,`npcflag`=0,`faction`=35,`AIName`='',
    `ScriptName`='npc_jade_forest_scouting_actor',
    `spell1`=0,`spell2`=0,`spell3`=0,`spell4`=0
WHERE `entry` IN (55671,55686,55702);
UPDATE `creature_template` SET `spell1`=104718,`spell2`=104717 WHERE `entry`=55686;
UPDATE `creature_template` SET `spell1`=104384 WHERE `entry`=55702;
UPDATE `creature_template` SET `AIName`='',`ScriptName`='npc_jade_forest_report_attacker'
WHERE `entry` IN (55692,55693);

-- These shared investigation targets retain SmartAI for the Alliance report.
-- The CreatureScript consumes only active Horde report interactions.
UPDATE `creature_template`
SET `npcflag`=`npcflag` | 1,`ScriptName`='npc_jade_forest_report_investigation'
WHERE `entry` IN (55378,55381);
UPDATE `gameobject_template` SET `ScriptName`='go_jade_forest_report_warning' WHERE `entry`=209615;

DELETE FROM `spell_script_names`
WHERE (`spell_id` IN (104739,104384) AND `ScriptName`='spell_jade_forest_report_shooting')
   OR (`spell_id` IN (104717,104718) AND `ScriptName`='spell_jade_forest_report_riko_attack');
INSERT INTO `spell_script_names` (`spell_id`,`ScriptName`) VALUES
(104384,'spell_jade_forest_report_shooting'),
(104717,'spell_jade_forest_report_riko_attack'),
(104718,'spell_jade_forest_report_riko_attack');

-- Present the reports in story order. Existing active quests remain active.
INSERT INTO `quest_template_addon` (`ID`,`PrevQuestID`) VALUES
(29730,29971),(29731,29730),(29823,29731),(29824,29823)
ON DUPLICATE KEY UPDATE `PrevQuestID`=VALUES(`PrevQuestID`);

-- The statue and widow POIs were both incorrectly mapped to the warning sign.
UPDATE `quest_poi` SET `ObjectiveIndex`=1,`QuestObjectiveId`=264503
WHERE `QuestID`=29730 AND `Idx1`=3;
UPDATE `quest_poi` SET `ObjectiveIndex`=2,`QuestObjectiveId`=264504
WHERE `QuestID`=29730 AND `Idx1`=2;
UPDATE `quest_poi_points` SET `X`=1503,`Y`=-1302
WHERE `QuestID`=29730 AND `Idx1`=2;
COMMIT;
