-- Quest 29792 "Bidden to Greatness": use the dedicated personal Mandori
-- gate (211294), matching the already-correct personal Pei-Wu gate (211298).
--
-- The old SmartAI summoned entry 210965 on top of the permanent 210965 spawn
-- and then activated the nearest object with that shared entry.  That made
-- the activation ambiguous and produced overlapping visible/collision gates.

UPDATE `smart_scripts`
SET `action_param1` = 211294,
    `comment` = 'Aysa Cloudsinger - On Summoned - Summon Personal Mandori Village Gate'
WHERE `entryorguid` = 59986
  AND `source_type` = 0
  AND `id` = 0
  AND `event_type` = 54
  AND `action_type` = 50
  AND `action_param1` = 210965;

UPDATE `smart_scripts`
SET `target_param1` = 211294,
    `comment` = 'Aysa Cloudsinger - On Script - Activate Personal Mandori Village Gate'
WHERE `entryorguid` = 5998600
  AND `source_type` = 9
  AND `id` = 2
  AND `action_type` = 9
  AND `target_type` = 20
  AND `target_param1` = 210965;
