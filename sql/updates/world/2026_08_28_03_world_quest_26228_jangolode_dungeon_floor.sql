-- Quest 26228 "Livin' the Life": Jangolode Mine is DungeonMap ID 580.
-- Its 5.4.8 client FloorIndex is 5 (ParentWorldMapID 39), not floor 1.
UPDATE `quest_poi`
SET `Floor` = 5
WHERE `QuestID` = 26228
  AND `Idx1` = 2
  AND `MapID` = 0
  AND `WorldMapAreaId` = 39;
