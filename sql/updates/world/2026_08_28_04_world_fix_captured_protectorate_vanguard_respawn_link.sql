-- Captured Protectorate Vanguard (20763) initializes its questgiver flag on
-- respawn.  Event 1 is a separate SMART_EVENT_ACCEPTED_QUEST handler, not a
-- SMART_EVENT_LINK action, so chaining the respawn row to it is invalid and
-- produces a runtime SmartScript::ProcessAction warning.

UPDATE `smart_scripts`
SET `link` = 0
WHERE `entryorguid` = 20763
  AND `source_type` = 0
  AND `id` = 0
  AND `link` = 1
  AND `event_type` = 11
  AND `action_type` = 81;
