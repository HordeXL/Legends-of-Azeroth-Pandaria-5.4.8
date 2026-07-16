-- Exact pre-change state for the 2026-07-16 restoration of creature templates
-- 35431 and 35433: neither template, model nor spell-click row existed.
-- The two existing SourceType 18 / spell 66245 condition rows are not changed
-- by the forward migration and therefore are intentionally not touched here.

START TRANSACTION;

DELETE FROM `npc_spellclick_spells`
WHERE `npc_entry` IN (35431, 35433)
  AND (`spell_id`, `cast_flags`, `user_type`) IN
      ((46598, 1, 0), (66245, 1, 0));

DELETE FROM `creature_template_model`
WHERE (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) IN
      ((35431, 0, 25292, 1, 1, 15595),
       (35433, 0, 26403, 1, 1, 15595));

DELETE FROM `creature_template`
WHERE (`entry` = 35431
       AND `name` = 'Siege Engine (1)'
       AND `IconName` = 'vehichleCursor'
       AND `faction` = 35
       AND `type` = 9
       AND `type_flags` = 393256
       AND `movementId` = 164
       AND `VerifiedBuild` = 15595)
   OR (`entry` = 35433
       AND `name` = 'Siege Engine (1)'
       AND `IconName` = 'vehichleCursor'
       AND `faction` = 35
       AND `type` = 9
       AND `type_flags` = 393256
       AND `movementId` = 113
       AND `VerifiedBuild` = 15595);

COMMIT;
