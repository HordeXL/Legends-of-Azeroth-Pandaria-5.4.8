-- Restore the action id from the repository's older valid SAI source.
-- The base dump changed this row to foreign/unsupported Action 134, while
-- this core defines Invoker Cast as Action 85. Keep Zidormi's existing C++
-- ScriptName; do not set AIName=SmartAI.

UPDATE `smart_scripts`
SET `action_type` = 85
WHERE `entryorguid` = 31848
  AND `source_type` = 0
  AND `id` = 0
  AND `event_type` = 62
  AND `event_param1` = 10131
  AND `event_param2` = 0
  AND `action_type` = 134
  AND `action_param1` = 46343
  AND `action_param2` = 2
  AND `comment` LIKE 'Zidormi%Invoker Cast%Teleport to Caverns of Time%';
