-- Mount Hyjal: Through the Dream (25325) leads directly to Return to
-- Nordrassil (25578).  The latter incorrectly required the unrelated Aviana
-- quest 25663, leaving players with no active quest after 25325 was rewarded.

UPDATE `quest_template_addon`
SET `PrevQuestID` = 25325
WHERE `ID` = 25578;
