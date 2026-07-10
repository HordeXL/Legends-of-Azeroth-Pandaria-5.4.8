-- Adapt the old ranked spell ids in Tapoke's source-backed SmartAI to 5.4.8.
-- This core defines Rogue Stealth as 1784 and Backstab as 53.

UPDATE `smart_scripts`
SET `action_param1`=1784
WHERE `entryorguid`=4962 AND `source_type`=0 AND `id` IN (0,3)
  AND `action_type` IN (11,28) AND `action_param1`=1785;

UPDATE `smart_scripts`
SET `action_param1`=53
WHERE `entryorguid`=4971 AND `source_type`=0 AND `id`=2
  AND `event_type`=67 AND `action_type`=11 AND `action_param1`=2589;
