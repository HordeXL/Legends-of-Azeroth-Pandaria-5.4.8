-- Gorrok (55162) stands outside spell 103014's allowed AreaGroup 3119.
-- Restore direct rescue credit for Regroup! (29694), preserving the existing
-- gossip selection and linked close-gossip action. Do not affect Mayor Honeydew.
UPDATE `smart_scripts`
SET `action_type` = 33, `action_param1` = 55162,
    `action_param2` = 0, `action_param3` = 0,
    `action_param4` = 0, `action_param5` = 0, `action_param6` = 0,
    `comment` = 'Sergeant Gorrok - Regroup gossip - Give rescue credit without area-restricted tracking spell'
WHERE `entryorguid` = 55162 AND `source_type` = 0 AND `id` = 0
  AND `event_type` = 62 AND `event_param1` = 13091
  AND `action_type` = 85 AND `action_param1` = 103014 AND `target_type` = 7;
