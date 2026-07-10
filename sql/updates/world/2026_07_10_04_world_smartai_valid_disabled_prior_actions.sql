-- Replace four earlier Action 0 rows, which this core rejects during DB
-- validation, with valid disabled/harmless actions.

-- These three rows are linked chain steps. Keep their outgoing links active
-- and use SET_EVENT_PHASE 0 as a harmless valid action. None of these scripts
-- uses an event phase mask. Preserve the old credit/summon id in param6.
UPDATE `smart_scripts`
SET `action_type` = 22,
    `action_param1` = 0,
    `action_param6` = 48195
WHERE `entryorguid` IN (48119, 48121)
  AND `source_type` = 0
  AND `id` = 1
  AND `event_type` = 61
  AND `link` = 2
  AND `event_phase_mask` = 0
  AND `action_type` = 0
  AND `action_param1` = 48195;

UPDATE `smart_scripts`
SET `action_type` = 22,
    `action_param1` = 0,
    `action_param6` = 57874
WHERE `entryorguid` = 56686
  AND `source_type` = 0
  AND `id` = 8
  AND `event_type` = 61
  AND `link` = 0
  AND `event_phase_mask` = 0
  AND `action_type` = 0
  AND `action_param1` = 57874;

-- Ramkahen Prisoner text group 3 no longer exists in the trusted flow and
-- waypoint start was moved to text group 2. No row links to id 12, so retain
-- the old row as an unreachable LINK event with a valid action.
UPDATE `smart_scripts`
SET `event_type` = 61,
    `action_type` = 22,
    `action_param1` = 0,
    `action_param6` = 46425
WHERE `entryorguid` = 46425
  AND `source_type` = 0
  AND `id` = 12
  AND `link` = 0
  AND `event_type` = 52
  AND `event_param1` = 3
  AND `event_phase_mask` = 0
  AND `action_type` = 0
  AND NOT EXISTS
  (
      SELECT 1
      FROM
      (
          SELECT `link`
          FROM `smart_scripts`
          WHERE `entryorguid` = 46425
            AND `source_type` = 0
            AND `link` = 12
          LIMIT 1
      ) AS `incoming_link`
  );
