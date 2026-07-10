-- Correct the Action 0 representation from the previous applied batch.
-- This core declares SMART_ACTION_NONE but rejects action type 0 in DB
-- validation. Convert the two rows to unreachable LINK events with a valid
-- harmless action. No other row links to either event id.
-- The foreign spell ids are retained in action_param6 and the comments.

UPDATE `smart_scripts`
SET `event_type` = 61,
    `action_type` = 22,
    `action_param1` = 0,
    `action_param6` = 223971,
    `comment` = 'Pterrorwing Skyscreamer - Disabled foreign Hunter''s Rush spell 223971 (not in 5.4.8)'
WHERE `entryorguid` = 70021
  AND `source_type` = 0
  AND `id` = 1
  AND `link` = 0
  AND `action_type` = 0
  AND `action_param1` = 223971
  AND NOT EXISTS
  (
      SELECT 1
      FROM
      (
          SELECT `link`
          FROM `smart_scripts`
          WHERE `entryorguid` = 70021
            AND `source_type` = 0
            AND `link` = 1
          LIMIT 1
      ) AS `incoming_link`
  );

UPDATE `smart_scripts`
SET `event_type` = 61,
    `action_type` = 22,
    `action_param1` = 0,
    `action_param6` = 215377,
    `comment` = 'Arnold Raygun - Disabled foreign The Maw Must Feed spell 215377 (not in 5.4.8)'
WHERE `entryorguid` = 70034
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 0
  AND `action_type` = 0
  AND `action_param1` = 215377;
