-- Exact rollback for quest_template_addon rows before adding the
-- QUEST_SPECIAL_FLAGS_EXPLORATION_OR_EVENT bit required by quest-complete spells.
-- Captured 2026-07-17 with Wampserver MySQL 5.7.44.

START TRANSACTION;

DELETE FROM `quest_template_addon` WHERE `ID` IN (30470, 32640, 32641);

INSERT INTO `quest_template_addon`
    (`ID`, `MaxLevel`, `AllowableClasses`, `SourceSpellID`, `PrevQuestID`,
     `NextQuestID`, `ExclusiveGroup`, `RewardMailTemplateID`, `RewardMailDelay`,
     `RequiredSkillID`, `RequiredSkillPoints`, `RequiredMinRepFaction`,
     `RequiredMaxRepFaction`, `RequiredMinRepValue`, `RequiredMaxRepValue`,
     `ProvidedItemCount`, `SpecialFlags`, `ScriptName`)
VALUES
    (30470, 0, 0, 0,     0, 0, 30470, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, ''),
    (32640, 0, 0, 0, 32708, 0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, ''),
    (32641, 0, 0, 0, 32708, 0,     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, '');

COMMIT;
