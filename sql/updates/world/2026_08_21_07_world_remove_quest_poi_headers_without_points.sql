-- Remove 11 incomplete quest POI headers which have no coordinate rows.
--
-- All referenced quests are valid content in or before client 5.4.8. This
-- update does not remove quests, objectives, or any quest_poi_points rows.
-- The latest local SFDB 548 release already omits eight of these headers. The
-- remaining three are also incomplete in the older TDB/SFDB sources: no
-- authentic coordinates exist, and the core ignores them on every startup.
-- The NOT EXISTS guard preserves a row if valid coordinates are supplied by
-- another update before this file is applied.

DELETE qp
FROM `quest_poi` qp
WHERE (qp.`QuestID`, qp.`Idx1`) IN
      ((3379,1), (6922,0), (10216,1), (11078,6), (24591,2),
       (27228,2), (28170,1), (29151,0), (29178,0), (29763,1),
       (32944,1))
  AND NOT EXISTS
      (SELECT 1
       FROM `quest_poi_points` qpp
       WHERE qpp.`QuestID` = qp.`QuestID`
         AND qpp.`Idx1` = qp.`Idx1`);
