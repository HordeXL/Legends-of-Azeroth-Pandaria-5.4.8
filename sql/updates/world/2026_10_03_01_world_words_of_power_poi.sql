-- Words of Power (11640 Horde, 11942 Alliance)
-- The imported POIs used obsolete objective indexes 4/5/6 and had no modern
-- quest objective IDs.  Bind each priest location to its actual item objective
-- so the client can hide completed priests and display the remaining two.

UPDATE `quest_poi`
SET `ObjectiveIndex` = 0, `QuestObjectiveId` = 262764
WHERE `QuestID` = 11640 AND `Idx1` = 0;

UPDATE `quest_poi`
SET `ObjectiveIndex` = 1, `QuestObjectiveId` = 262765
WHERE `QuestID` = 11640 AND `Idx1` = 1;

UPDATE `quest_poi`
SET `ObjectiveIndex` = 2, `QuestObjectiveId` = 262766
WHERE `QuestID` = 11640 AND `Idx1` = 2;

UPDATE `quest_poi`
SET `ObjectiveIndex` = 0, `QuestObjectiveId` = 253058
WHERE `QuestID` = 11942 AND `Idx1` = 0;

UPDATE `quest_poi`
SET `ObjectiveIndex` = 1, `QuestObjectiveId` = 253059
WHERE `QuestID` = 11942 AND `Idx1` = 1;

UPDATE `quest_poi`
SET `ObjectiveIndex` = 2, `QuestObjectiveId` = 253060
WHERE `QuestID` = 11942 AND `Idx1` = 2;
