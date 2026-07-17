-- Exact pre-change backup for quest_template_addon ID 14482.
-- Captured from the active `world` database with MySQL 5.7.44 on 2026-07-17.

START TRANSACTION;

DELETE FROM `quest_template_addon` WHERE `ID` = 14482;
INSERT INTO `quest_template_addon`
    (`ID`, `MaxLevel`, `AllowableClasses`, `SourceSpellID`, `PrevQuestID`, `NextQuestID`,
     `ExclusiveGroup`, `RewardMailTemplateID`, `RewardMailDelay`, `RequiredSkillID`,
     `RequiredSkillPoints`, `RequiredMinRepFaction`, `RequiredMaxRepFaction`,
     `RequiredMinRepValue`, `RequiredMaxRepValue`, `ProvidedItemCount`, `SpecialFlags`, `ScriptName`)
VALUES
    (14482, 0, 0, 0, 0, 24432, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');

COMMIT;
