-- Scarlet Halls: expose Reinforced Archery Targets as clickable to the client.
-- The target casts Heroic Defense on the player, boarding the player's vehicle
-- (2037, provided by the nearby target's periodic spell 113399).
-- Flags 2|4: target the clicker, use the NPC's owner as original caster. These
-- static, unowned targets have an empty owner GUID, so Spell falls back to the
-- actual NPC caster. Flags 2 alone attribute the aura to the player, which
-- prevents CONTROL_VEHICLE from boarding the target and breaks removal cleanup.
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` = 59163 AND `spell_id` = 113436;
INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`)
VALUES (59163, 113436, 6, 0);

-- Require the carrying vehicle aura and prevent taking a second shield.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 18
  AND `SourceGroup` = 59163 AND `SourceEntry` = 113436 AND `SourceId` = 0;
INSERT INTO `conditions`
(`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`,
 `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`,
 `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
VALUES
(18, 59163, 113436, 0, 0, 1, 0, 113399, 0, 0, 0, 0, 0, '', 'Archery target: clicker has carrying vehicle'),
(18, 59163, 113436, 0, 0, 1, 0, 113436, 0, 0, 1, 0, 0, '', 'Archery target: clicker is not already carrying a shield');
