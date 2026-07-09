-- Fix SmartAI startup validation errors where min/max style parameters were reversed or incomplete.
-- The changes keep the existing scripted behavior and fill missing companion values.

-- SMART_EVENT_REWARD_QUEST: QuestID, CooldownMin, CooldownMax.
-- Keep the existing 2 second cooldown and add the missing max value.
UPDATE `smart_scripts`
SET `event_param3`=2
WHERE `entryorguid`=17214 AND `source_type`=0 AND `id`=0 AND `event_type`=20
  AND `event_param1`=9463 AND `event_param2`=2 AND `event_param3`=0;

UPDATE `smart_scripts`
SET `event_param3`=2
WHERE `entryorguid`=17215 AND `source_type`=0 AND `id`=2 AND `event_type`=20
  AND `event_param1`=9473 AND `event_param2`=2 AND `event_param3`=0;

-- SMART_EVENT_HEALTH_PCT: HPMin, HPMax, RepeatMin, RepeatMax.
-- This row was stored as 15-0%; restore the normal 0-15% range.
UPDATE `smart_scripts`
SET `event_param1`=0,
    `event_param2`=15,
    `comment`='Darkspine Siren - Between 0-15% Health - Flee For Assist (No Repeat)'
WHERE `entryorguid`=25073 AND `source_type`=0 AND `id`=4 AND `event_type`=2
  AND `event_param1`=15 AND `event_param2`=0;

-- SMART_EVENT_REWARD_QUEST for Matthias Lehner: add missing max cooldown.
UPDATE `smart_scripts`
SET `event_param3`=1
WHERE `entryorguid`=32423 AND `source_type`=0 AND `id`=0 AND `event_type`=20
  AND `event_param1`=13398 AND `event_param2`=1 AND `event_param3`=0;

-- SMART_EVENT_DISTANCE_CREATURE: guid, entry, distance, repeat.
-- Keep the 5 yard distance and add a conservative repeat interval.
UPDATE `smart_scripts`
SET `event_param4`=500
WHERE `entryorguid`=3304100 AND `source_type`=9 AND `id`=0 AND `event_type`=75
  AND `event_param2`=33041 AND `event_param3`=5 AND `event_param4`=0;
