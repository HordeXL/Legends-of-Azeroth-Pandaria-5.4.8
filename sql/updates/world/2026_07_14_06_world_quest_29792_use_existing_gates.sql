-- Quest 29792 "Bidden to Greatness": use one gate object at each location.
-- The phase-2 world gates already occupy the correct positions. Summoning
-- personal gates on top of them creates the observed second visual/collision
-- copy. Keep the linked SmartAI sequence, replace both summon actions with
-- no-ops, and activate the existing world gates instead.

UPDATE `smart_scripts`
SET `action_type` = 0,
    `action_param1` = 0,
    `action_param2` = 0,
    `comment` = 'Aysa Cloudsinger - On Summoned - Use Existing Mandori Village Gate'
WHERE `entryorguid` = 59986 AND `source_type` = 0 AND `id` = 0
  AND `action_type` = 50 AND `action_param1` = 211294;

UPDATE `smart_scripts`
SET `action_type` = 0,
    `action_param1` = 0,
    `action_param2` = 0,
    `comment` = 'Aysa Cloudsinger - Linked To Id 0 - Use Existing Pei-Wu Forest Gate'
WHERE `entryorguid` = 59986 AND `source_type` = 0 AND `id` = 1
  AND `action_type` = 50 AND `action_param1` = 211298;

UPDATE `smart_scripts`
SET `target_param1` = 210965,
    `comment` = 'Aysa Cloudsinger - On Script - Activate Existing Mandori Village Gate'
WHERE `entryorguid` = 5998600 AND `source_type` = 9 AND `id` = 2
  AND `action_type` = 9 AND `target_type` = 20 AND `target_param1` = 211294;

UPDATE `smart_scripts`
SET `target_param1` = 210964,
    `comment` = 'Jojo Ironbrow - Linked To Id 8 - Activate Existing Pei-Wu Forest Gate'
WHERE `entryorguid` = 59989 AND `source_type` = 0 AND `id` = 9
  AND `action_type` = 9 AND `target_type` = 20 AND `target_param1` = 211298;
