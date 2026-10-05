-- Allow level-66 dungeon entrants to start the modern Durnholde quest chain
-- directly at Erozion, without completing the external Caverns of Time intro.
-- ObjectMgr derives prerequisites from BOTH PrevQuestID and incoming NextQuestID.
UPDATE `quest_template_addon` SET `PrevQuestID`=0
WHERE `ID`=29598 AND `PrevQuestID`=10282;
UPDATE `quest_template_addon` SET `NextQuestID`=0
WHERE `ID`=10282 AND `NextQuestID`=29598;
-- Preserve 29598 -> 29599, level requirements, bombs, objectives and rewards.
