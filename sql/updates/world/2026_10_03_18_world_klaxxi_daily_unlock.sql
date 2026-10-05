-- Klaxxi daily quests were all hard-gated behind A Cry From Darkness (31066).
-- Characters can advance through the later Klaxxi campaign without receiving
-- a rewarded record for that quest, permanently hiding every active daily.
-- Use the completed Klaxxi'vess hub unlock, The Klaxxi Council (31006), while
-- retaining each quest's normal reputation and pool-rotation restrictions.

UPDATE `quest_template_addon` qta
JOIN `quest_template` qt ON qt.`ID` = qta.`ID`
SET qta.`PrevQuestID` = 31006
WHERE qta.`PrevQuestID` = 31066
  AND (qt.`Flags` & 4096) <> 0;
