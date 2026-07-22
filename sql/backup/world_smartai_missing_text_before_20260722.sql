-- Rollback for 2026_07_22_04_world_restore_smartai_text_owners.sql
-- State before the repair:
--   * source GUID 121192 had been reused by Shoveltusk, while its SmartAI still
--     belonged to the missing ELM General Purpose Bunny spawn from SFDB 5.4.8;
--   * summoned Wugou (57760) had no creature_text group 0 and its TEXT_OVER
--     event still named the static Wugou entry 55539.

START TRANSACTION;

DELETE FROM `creature_text`
WHERE `CreatureID` = 57760 AND `GroupID` = 0 AND `ID` = 0;

UPDATE `smart_scripts`
SET `event_param2` = 55539
WHERE `entryorguid` = 57760
  AND `source_type` = 0
  AND `id` = 10
  AND `event_type` = 52
  AND `event_param1` = 0
  AND `event_param2` = 57760;

UPDATE `smart_scripts`
SET `entryorguid` = -121192
WHERE `entryorguid` = -4000095
  AND `source_type` = 0
  AND `id` = 0
  AND `event_type` = 38
  AND `event_param1` = 0
  AND `event_param2` = 1
  AND `action_type` = 1
  AND `action_param1` = 0;

DELETE FROM `creature_addon` WHERE `guid` = 4000095;
DELETE FROM `creature` WHERE `guid` = 4000095 AND `id` = 23837;

COMMIT;
