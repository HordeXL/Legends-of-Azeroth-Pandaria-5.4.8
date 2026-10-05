-- Where are My Reinforcements? (30993)
-- Ban's visible balloon had neither a vehicle kit nor a spell-click spell.
-- Restore boarding, gate it to the active quest, and bind the scripted flight.

START TRANSACTION;

UPDATE `creature_template`
SET `npcflag` = `npcflag` | 16777216,
    `IconName` = 'vehichleCursor',
    `VehicleId` = 2315,
    `AIName` = '',
    `ScriptName` = 'npc_bans_balloon'
WHERE `entry` = 62217;

DELETE FROM `npc_spellclick_spells`
WHERE `npc_entry` = 62217;

INSERT INTO `npc_spellclick_spells`
    (`npc_entry`, `spell_id`, `cast_flags`, `user_type`)
VALUES
    (62217, 46598, 1, 0);

DELETE FROM `conditions`
WHERE `SourceTypeOrReferenceId` = 18
  AND `SourceGroup` = 62217
  AND `SourceEntry` = 46598;

INSERT INTO `conditions`
    (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
     `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`,
     `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
    (18, 62217, 46598, 0, 0, 9, 0, 30993, 0, 0, 0, 0, 0, '',
     'Ban''s Balloon - Spell click requires Where are My Reinforcements active');

-- Accepting Ban's offer is the first talk objective. The ride script grants
-- the second objective (63603) only after reaching the monastery.
DELETE FROM `smart_scripts`
WHERE `entryorguid` = 61819
  AND `source_type` = 0
  AND `event_type` = 19
  AND `event_param1` = 30993;

INSERT INTO `smart_scripts`
    (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`,
     `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`,
     `event_param4`, `action_type`, `action_param1`, `target_type`, `comment`)
VALUES
    (61819, 0, 1, 0, 19, 0, 100, 0, 30993, 0, 0, 0, 33, 61819, 7,
     'Ban Bearheart - On quest 30993 accept - Credit ready-to-leave objective');

-- The destination Ban was present but could not finish the quest.
UPDATE `creature_template`
SET `npcflag` = `npcflag` | 2
WHERE `entry` = 62218;

DELETE FROM `creature_questender`
WHERE `id` = 62218 AND `quest` = 30993;

INSERT INTO `creature_questender` (`id`, `quest`)
VALUES (62218, 30993);

COMMIT;
