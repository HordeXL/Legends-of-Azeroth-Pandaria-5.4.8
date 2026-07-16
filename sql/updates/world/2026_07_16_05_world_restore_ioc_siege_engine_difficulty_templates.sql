-- Restore two Build-15595 Isle of Conquest Siege Engine difficulty templates.
-- Matching-version source:
--   SkyFire 5.4.8 SFDB full release 24.001 (final creature_template rows)
-- Supporting independent source:
--   Trinity TDB Build-15595 creature/model data and historical spell-click rows.
-- Existing rows are never overwritten or deleted.

START TRANSACTION;

INSERT INTO `creature_template`
    (`entry`, `name`, `femaleName`, `subname`, `IconName`, `faction`,
     `unit_class`, `unit_flags2`, `type`, `type_flags`, `Health_mod`,
     `movementId`, `VerifiedBuild`)
SELECT
    35431, 'Siege Engine (1)', '', '', 'vehichleCursor', 35,
    1, 2048, 9, 393256, 65.5185,
    164, 15595
WHERE NOT EXISTS
    (SELECT 1 FROM `creature_template` WHERE `entry` = 35431);

INSERT INTO `creature_template`
    (`entry`, `name`, `femaleName`, `subname`, `IconName`, `faction`,
     `unit_class`, `unit_flags2`, `type`, `type_flags`, `Health_mod`,
     `movementId`, `VerifiedBuild`)
SELECT
    35433, 'Siege Engine (1)', '', '', 'vehichleCursor', 35,
    1, 2048, 9, 393256, 65.5185,
    113, 15595
WHERE NOT EXISTS
    (SELECT 1 FROM `creature_template` WHERE `entry` = 35433);

INSERT INTO `creature_template_model`
    (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 35431, 0, 25292, 1, 1, 15595
WHERE EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 35431)
  AND NOT EXISTS
      (SELECT 1 FROM `creature_template_model`
       WHERE `CreatureID` = 35431 AND `Idx` = 0 AND `CreatureDisplayID` = 25292);

INSERT INTO `creature_template_model`
    (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 35433, 0, 26403, 1, 1, 15595
WHERE EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 35433)
  AND NOT EXISTS
      (SELECT 1 FROM `creature_template_model`
       WHERE `CreatureID` = 35433 AND `Idx` = 0 AND `CreatureDisplayID` = 26403);

INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`)
SELECT 35431, 46598, 1, 0
WHERE EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 35431)
  AND NOT EXISTS
      (SELECT 1 FROM `npc_spellclick_spells`
       WHERE `npc_entry` = 35431 AND `spell_id` = 46598);

INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`)
SELECT 35431, 66245, 1, 0
WHERE EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 35431)
  AND NOT EXISTS
      (SELECT 1 FROM `npc_spellclick_spells`
       WHERE `npc_entry` = 35431 AND `spell_id` = 66245);

INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`)
SELECT 35433, 46598, 1, 0
WHERE EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 35433)
  AND NOT EXISTS
      (SELECT 1 FROM `npc_spellclick_spells`
       WHERE `npc_entry` = 35433 AND `spell_id` = 46598);

INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`)
SELECT 35433, 66245, 1, 0
WHERE EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 35433)
  AND NOT EXISTS
      (SELECT 1 FROM `npc_spellclick_spells`
       WHERE `npc_entry` = 35433 AND `spell_id` = 66245);

COMMIT;
