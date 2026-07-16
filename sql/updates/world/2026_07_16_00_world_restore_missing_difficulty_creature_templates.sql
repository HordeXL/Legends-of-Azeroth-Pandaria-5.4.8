-- Restore four missing Build 15595 difficulty creature templates referenced by
-- spell conditions. Source: matching SkyFire 5.4.8 SFDB full release 24.001.
-- Existing rows are never overwritten; parent difficulty links are restored
-- only from their current zero value after the matching child exists.

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
  31317, 0, 0, 0, 0, 0,
  0, 0, 'Lava Blaze (1)', '', '', '', 0,
  81, 81, 2, 0, 103, 0, 0,
  1, 1.14286, 1, 0, 464, 604, 0, 708, 1.4,
  2000, 0, 1, 32768, 2048, 8, 0,
  0, 0, 0, 353, 512, 112,
  4, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, '', 0, 1,
  5, 1, 1, 1, 0,
  0, 0, 0, 0, 0, 0,
  121, 1, 0, 0, 0, 0, '', 15595
WHERE NOT EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 31317);

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
  33906, 0, 0, 0, 0, 0,
  0, 0, 'Focused Eyebeam (1)', '', '', '', 0,
  81, 81, 2, 0, 14, 0, 0,
  2.2, 1.14286, 1, 0, 464, 604, 0, 708, 1,
  2000, 0, 1, 33554432, 2048, 8, 0,
  0, 0, 0, 353, 512, 112,
  10, 1024, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, '', 0, 1,
  2, 1, 1, 1, 0,
  0, 0, 0, 0, 0, 0,
  98, 1, 0, 0, 0, 0, '', 15595
WHERE NOT EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 33906);

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
  33909, 0, 0, 0, 0, 0,
  0, 0, 'Kologarn (1)', '', '', '', 0,
  80, 80, 2, 0, 16, 0, 0,
  1, 1.14286, 1, 3, 417, 582, 0, 608, 70,
  2000, 0, 1, 33554432, 2048, 8, 0,
  0, 0, 0, 341, 506, 80,
  5, 4194412, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, '', 0, 1,
  1100, 50, 1, 1, 0,
  0, 0, 0, 0, 0, 0,
  0, 1, 0, 0, 617299839, 0, '', 15595
WHERE NOT EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 33909);

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
  40684, 0, 0, 0, 0, 0,
  0, 0, 'Living Ember (1)', '', '', '', 0,
  82, 82, 2, 0, 14, 0, 0,
  1, 1.14286, 1, 1, 0, 0, 0, 0, 1,
  0, 0, 1, 0, 2048, 0, 0,
  0, 0, 0, 0, 0, 0,
  4, 72, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, '', 0, 1,
  15, 1, 1, 1, 0,
  0, 0, 0, 0, 0, 0,
  172, 1, 0, 0, 0, 0, '', 15595
WHERE NOT EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 40684);

INSERT INTO `creature_template_model`
  (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 31317, 0, 2172, 1, 1, 15595
WHERE EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 31317)
  AND EXISTS (SELECT 1 FROM `creature_model_info` WHERE `modelid` = 2172)
  AND NOT EXISTS (SELECT 1 FROM `creature_template_model` WHERE `CreatureID` = 31317 AND `CreatureDisplayID` = 2172);

INSERT INTO `creature_template_model`
  (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 33906, 0, 11686, 1, 1, 15595
WHERE EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 33906)
  AND EXISTS (SELECT 1 FROM `creature_model_info` WHERE `modelid` = 11686)
  AND NOT EXISTS (SELECT 1 FROM `creature_template_model` WHERE `CreatureID` = 33906 AND `CreatureDisplayID` = 11686);

INSERT INTO `creature_template_model`
  (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 33906, 1, 1126, 1, 1, 15595
WHERE EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 33906)
  AND EXISTS (SELECT 1 FROM `creature_model_info` WHERE `modelid` = 1126)
  AND NOT EXISTS (SELECT 1 FROM `creature_template_model` WHERE `CreatureID` = 33906 AND `CreatureDisplayID` = 1126);

INSERT INTO `creature_template_model`
  (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 33909, 0, 28638, 1, 1, 15595
WHERE EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 33909)
  AND EXISTS (SELECT 1 FROM `creature_model_info` WHERE `modelid` = 28638)
  AND NOT EXISTS (SELECT 1 FROM `creature_template_model` WHERE `CreatureID` = 33909 AND `CreatureDisplayID` = 28638);

INSERT INTO `creature_template_model`
  (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 40684, 0, 1070, 1, 1, 15595
WHERE EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 40684)
  AND EXISTS (SELECT 1 FROM `creature_model_info` WHERE `modelid` = 1070)
  AND NOT EXISTS (SELECT 1 FROM `creature_template_model` WHERE `CreatureID` = 40684 AND `CreatureDisplayID` = 1070);

UPDATE `creature_template` parent
JOIN `creature_template` child ON child.`entry` = 31317
SET parent.`difficulty_entry_1` = 31317
WHERE parent.`entry` = 30643 AND parent.`name` = 'Lava Blaze' AND parent.`difficulty_entry_1` = 0;

UPDATE `creature_template` parent
JOIN `creature_template` child ON child.`entry` = 33906
SET parent.`difficulty_entry_1` = 33906
WHERE parent.`entry` = 33632 AND parent.`name` = 'Focused Eyebeam' AND parent.`difficulty_entry_1` = 0;

UPDATE `creature_template` parent
JOIN `creature_template` child ON child.`entry` = 33909
SET parent.`difficulty_entry_1` = 33909
WHERE parent.`entry` = 32930 AND parent.`name` = 'Kologarn' AND parent.`difficulty_entry_1` = 0;

UPDATE `creature_template` parent
JOIN `creature_template` child ON child.`entry` = 40684
SET parent.`difficulty_entry_1` = 40684
WHERE parent.`entry` = 40683 AND parent.`name` = 'Living Ember' AND parent.`difficulty_entry_1` = 0;

COMMIT;
