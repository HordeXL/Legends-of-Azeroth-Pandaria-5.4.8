-- Exact rollback for the 13 areatrigger quest SpecialFlags repairs.
-- Captured 2026-07-17 with Wampserver MySQL 5.7.44.
-- Quest-addon rows 29536 and 29539 were absent before the repair.
-- The 13 areatrigger_involvedrelation rows are intentionally not changed.

START TRANSACTION;

DELETE FROM `quest_template_addon`
WHERE `ID` IN
    (869, 13564, 14066, 25621, 26512, 26930, 27007, 27152, 27610,
     29392, 29415, 29536, 29539);

INSERT INTO `quest_template_addon`
    (`ID`, `MaxLevel`, `AllowableClasses`, `SourceSpellID`, `PrevQuestID`,
     `NextQuestID`, `ExclusiveGroup`, `RewardMailTemplateID`, `RewardMailDelay`,
     `RequiredSkillID`, `RequiredSkillPoints`, `RequiredMinRepFaction`,
     `RequiredMaxRepFaction`, `RequiredMinRepValue`, `RequiredMaxRepValue`,
     `ProvidedItemCount`, `SpecialFlags`, `ScriptName`)
VALUES
    (869,   0, 0, 0,     0,  3281, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
    (13564, 0, 0, 0, 13529,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
    (14066, 0, 0, 0, 13991,   869, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
    (25621, 0, 0, 0, 25616, 25622, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
    (26512, 0, 0, 0, 26510, 26514, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
    (26930, 0, 0, 0, 26926,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
    (27007, 0, 0, 0, 26260, 27010, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
    (27152, 0, 0, 0, 27151, 27153, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
    (27610, 0, 0, 0, 27607,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
    (29392, 0, 0, 0,     0, 29398, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
    (29415, 0, 0, 0,     0, 29416, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');

COMMIT;
