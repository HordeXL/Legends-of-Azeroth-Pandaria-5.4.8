-- Restore the missing Build 15595 Drakkari Invader variant referenced by
-- SmartAI and Trollgore spell conditions. Source: matching SFDB 5.4.8 base.
-- The current schema stores display IDs in creature_template_model.

START TRANSACTION;

INSERT INTO `creature_template` (
  `entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `difficulty_entry_4`, `difficulty_entry_5`,
  `KillCredit1`, `KillCredit2`, `name`, `femaleName`, `subname`, `IconName`, `gossip_menu_id`,
  `minlevel`, `maxlevel`, `exp`, `exp_unk`, `faction`, `npcflag`, `npcflag2`,
  `speed_walk`, `speed_run`, `scale`, `rank`, `mindmg`, `maxdmg`, `dmgschool`, `attackpower`, `dmg_multiplier`,
  `BaseAttackTime`, `RangeAttackTime`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`,
  `trainer_type`, `trainer_class`, `trainer_race`, `minrangedmg`, `maxrangedmg`, `rangedattackpower`,
  `type`, `type_flags`, `type_flags2`, `lootid`, `pickpocketloot`, `skinloot`,
  `resistance1`, `resistance2`, `resistance3`, `resistance4`, `resistance5`, `resistance6`,
  `spell1`, `spell2`, `spell3`, `spell4`, `spell5`, `spell6`, `spell7`, `spell8`,
  `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`,
  `Health_mod`, `Mana_mod`, `Mana_mod_extra`, `Armor_mod`, `RacialLeader`,
  `questItem1`, `questItem2`, `questItem3`, `questItem4`, `questItem5`, `questItem6`,
  `movementId`, `RegenHealth`, `VignetteID`, `TrackingQuestID`, `mechanic_immune_mask`, `flags_extra`, `ScriptName`, `VerifiedBuild`
)
SELECT
  27754, 0, 0, 0, 0, 0,
  0, 0, 'Drakkari Invader', '', '', '', 0,
  74, 75, 2, 0, 35, 0, 0,
  1, 1.14286, 1, 0, 342, 485, 0, 392, 1,
  2000, 0, 1, 0, 2048, 8, 0,
  0, 0, 0, 295, 438, 68,
  7, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 'SmartAI', 0, 1,
  0.188058, 0.5, 1, 1, 0,
  0, 0, 0, 0, 0, 0,
  0, 1, 0, 0, 0, 0, '', 15595
WHERE NOT EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 27754);

INSERT INTO `creature_template_model`
  (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 27754, 0, 27079, 1, 1, 15595
WHERE EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 27754)
  AND EXISTS (SELECT 1 FROM `creature_model_info` WHERE `modelid` = 27079)
  AND NOT EXISTS (SELECT 1 FROM `creature_template_model` WHERE `CreatureID` = 27754 AND `CreatureDisplayID` = 27079);

INSERT INTO `creature_template_model`
  (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 27754, 1, 27080, 1, 1, 15595
WHERE EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 27754)
  AND EXISTS (SELECT 1 FROM `creature_model_info` WHERE `modelid` = 27080)
  AND NOT EXISTS (SELECT 1 FROM `creature_template_model` WHERE `CreatureID` = 27754 AND `CreatureDisplayID` = 27080);

INSERT INTO `creature_template_model`
  (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 27754, 2, 27081, 1, 1, 15595
WHERE EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 27754)
  AND EXISTS (SELECT 1 FROM `creature_model_info` WHERE `modelid` = 27081)
  AND NOT EXISTS (SELECT 1 FROM `creature_template_model` WHERE `CreatureID` = 27754 AND `CreatureDisplayID` = 27081);

COMMIT;
