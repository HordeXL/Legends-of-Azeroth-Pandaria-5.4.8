-- Blending In (11633)
-- The original Temple trigger SmartAI cast legacy credit spells 45627-45629.
-- Those spells no longer advance the creature-type quest objectives on this
-- core, so give the matching kill credit directly to the nearby player.

UPDATE `smart_scripts`
SET `action_type` = 33,
    `action_param1` = `entryorguid`,
    `action_param2` = 0,
    `action_param3` = 0,
    `action_param4` = 0,
    `action_param5` = 0,
    `action_param6` = 0,
    `comment` = CONCAT('Blending In - Near Temple trigger - Quest credit ', `entryorguid`)
WHERE `source_type` = 0
  AND `entryorguid` IN (25471, 25472, 25473)
  AND `event_type` = 10;
