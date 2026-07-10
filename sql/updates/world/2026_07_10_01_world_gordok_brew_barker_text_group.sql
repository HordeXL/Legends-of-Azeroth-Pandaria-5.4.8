-- Use the existing Gordok Brew Barker random yell group for the Horde spawn.
-- GroupID 1 does not exist; GroupID 0 contains the authentic Barker lines.

UPDATE `smart_scripts`
SET `action_param1` = 0,
    `comment` = 'Gordok Brew Barker - Out of Combat - Yell Line 0 (random) (P1)'
WHERE `entryorguid` = -84711
  AND `source_type` = 0
  AND `id` = 4
  AND `event_type` = 1
  AND `event_phase_mask` = 1
  AND `action_type` = 1
  AND `action_param1` = 1
  AND EXISTS
  (
      SELECT 1
      FROM `creature_text`
      WHERE `CreatureID` = 23685
        AND `GroupID` = 0
  );
