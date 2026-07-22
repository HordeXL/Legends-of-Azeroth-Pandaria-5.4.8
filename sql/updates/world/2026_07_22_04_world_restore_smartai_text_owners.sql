-- Restore the correct owners of two SmartAI TALK actions reported at startup.
--
-- 1. SFDB 5.4.8 has GUID 121192 as ELM General Purpose Bunny (entry 23837)
--    at 6816.33, 3801.11, 621.153 on map 571. In this merged database that
--    GUID is occupied by Shoveltusk, but the old GUID-specific SmartAI row was
--    retained. Restore the missing bunny with an unused local GUID and move
--    only that exact SmartAI row to it.
-- 2. Summoned Wugou (entry 57760) uses the same line as static Wugou (55539),
--    but its creature_text row was missing and TEXT_OVER still named 55539.

START TRANSACTION;

INSERT INTO `creature`
    (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`,
     `phaseId`, `phaseGroup`, `modelid`, `equipment_id`,
     `position_x`, `position_y`, `position_z`, `orientation`,
     `spawntimesecs`, `spawntimesecs_max`, `wander_distance`,
     `currentwaypoint`, `curhealth`, `curmana`, `MovementType`,
     `npcflag`, `npcflag2`, `unit_flags`, `unit_flags2`, `dynamicflags`,
     `ScriptName`, `walk_mode`, `VerifiedBuild`)
SELECT 4000095, 23837, 571, 210, 4528, 1, 1,
       0, 0, 11686, 0,
       6816.33, 3801.11, 621.153, 0.802851,
       300, 0, 0,
       0, 42, 0, 0,
       0, 0, 0, 0, 0,
       '', 0, 0
WHERE NOT EXISTS (
    SELECT 1 FROM `creature` WHERE `guid` = 4000095
);

INSERT INTO `creature_addon` (`guid`)
SELECT 4000095
WHERE EXISTS (
    SELECT 1
    FROM `creature`
    WHERE `guid` = 4000095
      AND `id` = 23837
      AND `map` = 571
      AND ABS(`position_x` - 6816.33) < 0.01
      AND ABS(`position_y` - 3801.11) < 0.01
)
AND NOT EXISTS (
    SELECT 1 FROM `creature_addon` WHERE `guid` = 4000095
);

UPDATE `smart_scripts` AS `s`
JOIN `creature` AS `c`
  ON `c`.`guid` = 4000095
 AND `c`.`id` = 23837
 AND `c`.`map` = 571
 AND ABS(`c`.`position_x` - 6816.33) < 0.01
 AND ABS(`c`.`position_y` - 3801.11) < 0.01
SET `s`.`entryorguid` = -4000095
WHERE `s`.`entryorguid` = -121192
  AND `s`.`source_type` = 0
  AND `s`.`id` = 0
  AND `s`.`event_type` = 38
  AND `s`.`event_param1` = 0
  AND `s`.`event_param2` = 1
  AND `s`.`action_type` = 1
  AND `s`.`action_param1` = 0;

INSERT INTO `creature_text`
    (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Language`,
     `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`,
     `BroadcastTextId`, `TextRange`, `comment`)
SELECT 57760, `GroupID`, `ID`, `Text`, `Type`, `Language`,
       `Probability`, `Emote`, `Duration`, `Sound`, `SoundType`,
       `BroadcastTextId`, `TextRange`, 'Wugou (summoned)'
FROM `creature_text` AS `source_text`
WHERE `source_text`.`CreatureID` = 55539
  AND `source_text`.`GroupID` = 0
  AND `source_text`.`ID` = 0
  AND NOT EXISTS (
      SELECT 1
      FROM `creature_text` AS `existing_text`
      WHERE `existing_text`.`CreatureID` = 57760
        AND `existing_text`.`GroupID` = 0
        AND `existing_text`.`ID` = 0
  );

UPDATE `smart_scripts`
SET `event_param2` = 57760
WHERE `entryorguid` = 57760
  AND `source_type` = 0
  AND `id` = 10
  AND `event_type` = 52
  AND `event_param1` = 0
  AND `event_param2` = 55539;

COMMIT;
