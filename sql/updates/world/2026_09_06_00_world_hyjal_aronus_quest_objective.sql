-- Quest 25316 "As Hyjal Burns" / 海加尔在燃烧 had no rows in quest_objective,
-- so an accepted quest stayed QUEST_STATUS_INCOMPLETE forever and the Aronus
-- (39140) spellclick script -- which only fires the flight when the quest is
-- QUEST_STATUS_COMPLETE -- never triggered.
--
-- Adding a TALKTO objective for Aronus restores the intended flow: the spell
-- click handler calls Player::TalkedToCreature (satisfying the objective and
-- completing the quest) BEFORE the creature AI hook runs, so the same click
-- passes the script check and summons the flight.

DELETE FROM `quest_objective`
 WHERE `questId` = 25316
   AND `id` = 289861;

INSERT INTO `quest_objective`
    (`questId`, `id`, `index`, `type`, `objectId`, `amount`, `flags`, `description`)
VALUES
    (25316, 289861, 0, 3, 39140, 1, 0, 'Speak with Aronus');

DELETE FROM `quest_objectives_locale`
 WHERE `Id` = 289861
   AND `locale` = 'zhCN';

INSERT INTO `quest_objectives_locale`
    (`Id`, `locale`, `Description`)
VALUES
    (289861, 'zhCN', '与阿隆努斯交谈');

-- Expected: exactly one TALKTO objective for Aronus with its zhCN text.
SELECT `questId`, `id`, `index`, `type`, `objectId`, `amount`, `description`
  FROM `quest_objective`
 WHERE `questId` = 25316;

SELECT `Id`, `locale`, `Description`
  FROM `quest_objectives_locale`
 WHERE `Id` = 289861;
