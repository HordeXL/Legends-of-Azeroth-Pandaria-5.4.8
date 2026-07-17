-- Call of Duty (quest 14482) is completed by SmartAI action 15
-- (AreaExploredOrEventHappens). Without SpecialFlags bit 2 the core rejects both
-- SmartAI rows during startup, so the ship arrival event cannot complete the quest.

START TRANSACTION;

UPDATE `quest_template_addon`
SET `SpecialFlags` = `SpecialFlags` | 2
WHERE `ID` = 14482
  AND (`SpecialFlags` & 2) = 0;

COMMIT;
